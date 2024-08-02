defmodule TaskMaster.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias TaskMaster.Repo

  alias TaskMaster.Tasks.Task
  alias TaskMaster.Tasks.TaskParticipation

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks(org_id) do
    Task
    |> Task.for_org(org_id)
    |> Repo.all()
    |> Repo.preload([:task_participations, :participants])
  end

  def get_task!(id, org_id) do
    Task
    |> Task.for_org(org_id)
    |> Repo.get!(id)
    |> Repo.preload([:task_participations, :participants])
  end

  def create_task(attrs \\ %{}, participants \\ [], org_id) do
    attrs = Map.put(attrs, :organization_id, org_id)

    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, task} ->
        add_participants(task, participants, org_id)
        {:ok, Repo.preload(task, :participants)}

      error ->
        error
    end
  end

  def update_task(%Task{} = task, attrs, participants \\ [], org_id) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_task} ->
        update_participants(updated_task, participants, org_id)
        {:ok, Repo.preload(updated_task, :participants)}

      error ->
        error
    end
  end

  def delete_task(%Task{} = task, org_id) do
    if task.organization_id == org_id do
      Repo.delete(task)
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

  def list_tasks_with_participants do
    Task
    |> Repo.all()
    |> Repo.preload(:participants)
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
end
