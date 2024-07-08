defmodule TaskMaster.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskMaster.Tasks` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    user = TaskMaster.AccountsFixtures.user_fixture()

    valid_attrs = %{
      title: "some title",
      description: "some description",
      due_date: ~D[2024-06-28],
      status: :open,
      priority: :medium,
      indoor: false,
      created_by: user.id
    }

    {:ok, task} =
      attrs
      |> Enum.into(valid_attrs)
      |> TaskMaster.Tasks.create_task()

    task
  end
end
