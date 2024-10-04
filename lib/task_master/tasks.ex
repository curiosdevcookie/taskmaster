defmodule TaskMaster.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias TaskMaster.Repo

  alias TaskMaster.Tasks.Task
  alias TaskMaster.Tasks.TaskParticipation
  alias TaskMaster.Accounts
  require Logger

  defmacro asc_nulls_first(column) do
    quote do: fragment("? ASC NULLS FIRST", unquote(column))
  end

  defmacro desc_nulls_last(column) do
    quote do: fragment("? DESC NULLS LAST", unquote(column))
  end

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """

  def list_tasks(org_id, sort_criteria \\ []) do
    Task
    |> Task.for_org(org_id)
    |> apply_sort_criteria(sort_criteria)
    |> Repo.all()
    |> Repo.preload([:task_participations, :participants])
  end

  def list_parent_tasks(org_id, sort_criteria \\ []) do
    Task
    |> Task.for_org(org_id)
    |> where([t], is_nil(t.parent_task_id))
    |> apply_sort_criteria(sort_criteria)
    |> Repo.all()
    |> Repo.preload([:task_participations, :participants])
  end

  def list_subtasks(org_id) do
    Task
    |> Task.for_org(org_id)
    |> where([t], not is_nil(t.parent_task_id))
    |> Repo.all()
    |> Repo.preload([:task_participations, :participants])
  end

  defp apply_sort_criteria(query, sort_criteria) do
    Enum.reduce(sort_criteria, query, fn {field, order}, acc ->
      case order do
        :asc ->
          order_by(acc, [t], asc_nulls_first(field(t, ^field)))

        :desc ->
          order_by(acc, [t], desc_nulls_last(field(t, ^field)))
      end
    end)
  end

  def get_task!(id, _org_id) when is_nil(id), do: %Task{}

  def get_task!(id, org_id) do
    Task
    |> Task.for_org(org_id)
    |> Repo.get!(id)
    |> Repo.preload([:task_participations, :participants])
  end

  def create_task(attrs \\ %{}, participants \\ [], org_id, parent_task_id \\ nil) do
    attrs = Map.merge(attrs, %{"parent_task_id" => parent_task_id})

    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, task} ->
        task = add_participants(task, participants, org_id)
        task = Repo.preload(task, :participants)
        {:ok, updated_parent_task} = update_parent_task(task)
        broadcast({:ok, updated_parent_task}, :task_created)
        {:ok, task}

      error ->
        error
    end
  end

  def award_or_remove_stars_from_participants(task, old_status) do
    task = Repo.preload(task, :participants)

    Logger.info(
      "Awarding or removing stars. Task ID: #{task.id}, Old status: #{old_status}, New status: #{task.status}"
    )

    Enum.each(task.participants, fn participant ->
      Logger.info("Processing participant #{participant.id}")
      Logger.info("Participant current stars: #{participant.stars}")

      case {old_status, task.status} do
        {:completed, status} when status in [:open, :progressing] ->
          Logger.info("Attempting to decrement star for user #{participant.id}")

          case Accounts.decrement_user_stars(participant) do
            {:ok, updated_user} ->
              Logger.info("User #{participant.id} stars after decrement: #{updated_user.stars}")

            error ->
              Logger.error(
                "Failed to decrement stars for user #{participant.id}: #{inspect(error)}"
              )
          end

        {status, :completed} when status in [:open, :progressing] ->
          Logger.info("Attempting to increment star for user #{participant.id}")

          case Accounts.increment_user_stars(participant) do
            {:ok, updated_user} ->
              Logger.info("User #{participant.id} stars after increment: #{updated_user.stars}")

            error ->
              Logger.error(
                "Failed to increment stars for user #{participant.id}: #{inspect(error)}"
              )
          end

        _ ->
          Logger.info("No change in completion status for user #{participant.id}")
      end
    end)

    task
  end

  def update_task(%Task{} = task, attrs, participants \\ [], org_id) do
    Logger.info(
      "Updating task #{task.id}. Current status: #{task.status}, New status: #{attrs[:status]}"
    )

    result = do_update_task(task, attrs, participants, org_id)

    case result do
      {:ok, updated_task} ->
        Logger.info(
          "Task #{updated_task.id} successfully updated. New status: #{updated_task.status}"
        )

        # Return just the updated_task, not a tuple
        updated_task

      {:error, _} = error ->
        Logger.error("Failed to update task: #{inspect(error)}")
        error
    end
  end

  defp do_update_task(task, attrs, participants, org_id) do
    old_status = task.status
    Logger.info("Updating task #{task.id}. Old status: #{old_status}")

    attrs = maybe_set_completed_at(attrs, task)
    Logger.info("Attributes after maybe_set_completed_at: #{inspect(attrs)}")

    Repo.transaction(fn ->
      with {:ok, updated_task} <- Task.changeset(task, attrs) |> Repo.update(),
           _ <- Logger.info("Task updated in DB. New status: #{updated_task.status}"),
           updated_task <- update_participants(updated_task, participants, org_id),
           updated_task <- Repo.preload(updated_task, :participants),
           updated_task <- award_or_remove_stars_from_participants(updated_task, old_status),
           {:ok, parent_updated_task} <- update_parent_task(updated_task) do
        TaskMasterWeb.Endpoint.broadcast("task_updates", "task_updated", updated_task)

        if parent_updated_task,
          do:
            TaskMasterWeb.Endpoint.broadcast("task_updates", "task_updated", parent_updated_task)

        broadcast({:ok, updated_task}, :task_updated)
        broadcast({:ok, parent_updated_task}, :task_updated)

        # Return just the updated_task, not a tuple
        updated_task
      else
        error ->
          Logger.error("Failed to update task: #{inspect(error)}")
          broadcast(error, :task_update_failed)
          Repo.rollback(error)
      end
    end)
  end

  defp update_parent_task(%Task{parent_task_id: nil} = task), do: {:ok, task}

  defp update_parent_task(%Task{parent_task_id: parent_task_id} = task) do
    parent_task = get_task!(parent_task_id, task.organization_id)
    subtasks_duration = calculate_subtasks_duration(parent_task_id)
    subtasks_participants = get_subtasks_participants(parent_task_id)
    new_status = get_parent_task_status(parent_task_id)

    all_participants = subtasks_participants |> Enum.uniq_by(& &1.id)

    do_update_task(
      parent_task,
      %{
        duration: subtasks_duration,
        status: new_status
      },
      all_participants,
      task.organization_id
    )
  end

  def calculate_subtasks_duration(parent_task_id) do
    from(t in Task,
      where: t.parent_task_id == ^parent_task_id and t.status != :completed,
      select: sum(t.duration)
    )
    |> Repo.one()
  end

  def get_subtasks_participants(parent_task_id) do
    Task
    |> where([t], t.parent_task_id == ^parent_task_id and t.status != :completed)
    |> Repo.all()
    |> Enum.flat_map(fn subtask ->
      subtask = Repo.preload(subtask, :participants, force: true)
      subtask.participants
    end)
    |> Enum.uniq_by(& &1.id)
  end

  defp get_parent_task_status(parent_task_id) do
    subtasks = from(t in Task, where: t.parent_task_id == ^parent_task_id) |> Repo.all()

    cond do
      Enum.all?(subtasks, &(&1.status == :completed)) -> :completed
      Enum.any?(subtasks, &(&1.status == :completed)) -> :progressing
      true -> :open
    end
  end

  defp maybe_set_completed_at(%{"status" => status} = attrs, %Task{status: old_status}) do
    case status do
      "completed" when old_status != "completed" ->
        Map.put(attrs, "completed_at", NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))

      status when status in ["open", "progressing"] ->
        Map.put(attrs, "completed_at", nil)

      _ ->
        attrs
    end
  end

  defp maybe_set_completed_at(attrs, _task), do: attrs

  def delete_task(%Task{} = task, org_id) do
    if task.organization_id == org_id do
      result = task |> Repo.delete()
      {:ok, updated_parent_task} = update_parent_task(%{task | id: task.parent_task_id})
      broadcast({:ok, updated_parent_task}, :task_deleted)
      result
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  @doc """
  Task participations
  """

  def create_task_participation(attrs \\ %{}) do
    %TaskParticipation{}
    |> TaskParticipation.changeset(attrs)
    |> Repo.insert()
  end

  def delete_task_participation(%TaskParticipation{} = task_participation) do
    Repo.delete(task_participation)
  end

  def get_task_participation!(user_id, task_id) do
    Repo.get_by!(TaskParticipation, user_id: user_id, task_id: task_id)
  end

  def list_task_participants(nil), do: []

  def list_task_participants(task_id) do
    Task
    |> Repo.get!(task_id)
    |> Repo.preload(:participants)
    |> Map.get(:participants)
  end

  def list_user_participated_tasks(user_id) do
    User
    |> Repo.get!(user_id)
    |> Repo.preload(:participated_tasks)
    |> Map.get(:participated_tasks)
  end

  def preload_task_participants(task) do
    Repo.preload(task, :participants)
  end

  def update_task_participants(task, participants) do
    task
    |> Task.changeset(%{participants: participants})
    |> Repo.update()
  end

  defp add_participants(task, participants, org_id) do
    Enum.each(participants, fn participant ->
      if participant.organization_id == org_id do
        %TaskParticipation{}
        |> TaskParticipation.changeset(%{task_id: task.id, user_id: participant.id})
        |> Repo.insert()
      end
    end)

    task
  end

  defp update_participants(task, new_participants, org_id) do
    current_participants = list_task_participants(task.id)

    # Remove participants that are not in the new list
    Enum.each(current_participants, fn participant ->
      unless Enum.member?(new_participants, participant) do
        get_task_participation!(participant.id, task.id)
        |> Repo.delete()
      end
    end)

    # Add new participants
    Enum.each(new_participants, fn participant ->
      if participant.organization_id == org_id && !Enum.member?(current_participants, participant) do
        %TaskParticipation{}
        |> TaskParticipation.changeset(%{task_id: task.id, user_id: participant.id})
        |> Repo.insert()
      end
    end)

    Repo.preload(task, :participants, force: true)
  end

  def list_task_participants(task_id, org_id) do
    Task
    |> Task.for_org(org_id)
    |> Repo.get!(task_id)
    |> Repo.preload(:participants)
    |> Map.get(:participants)
  end

  def list_user_participated_tasks(user_id, org_id) do
    from(t in Task,
      join: tp in TaskParticipation,
      on: t.id == tp.task_id,
      where: tp.user_id == ^user_id and t.organization_id == ^org_id
    )
    |> Repo.all()
    |> Repo.preload(:participants)
  end

  def subscribe(org_id) do
    Phoenix.PubSub.subscribe(TaskMaster.PubSub, "tasks:#{org_id}")
  end

  def broadcast({:ok, task}, event)
      when event in [:task_created, :task_deleted, :task_updated] do
    Phoenix.PubSub.broadcast(TaskMaster.PubSub, "tasks:#{task.organization_id}", {event, task})
    {:ok, task}
  end

  def broadcast({:error, _} = error, _event), do: error
end
