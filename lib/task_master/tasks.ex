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
  def list_tasks do
    Repo.all(Task)
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id) do
    Task
    |> Repo.get!(id)
    |> Repo.preload([:task_participations, :participants])
  end

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
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
end
