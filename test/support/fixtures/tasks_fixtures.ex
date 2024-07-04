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

    {:ok, task} =
      attrs
      |> Enum.into(%{
        title: "some title",
        description: "some description",
        due_date: ~D[2024-06-28],
        status: :open,
        priority: 42,
        reminder_time: ~N[2024-06-28 13:17:00],
        priority_level: :low,
        is_recurring: true,
        created_by: user.id
      })
      |> TaskMaster.Tasks.create_task()

    task
  end
end
