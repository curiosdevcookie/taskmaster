defmodule TaskMaster.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskMaster.Tasks` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    {:ok, task} =
      attrs
      |> Enum.into(%{
        completed_at: ~N[2024-06-28 13:17:00],
        description: "some description",
        due_date: ~D[2024-06-28],
        duration: 42,
        indoor: true,
        priority: :low,
        status: :open,
        title: "some title"
      })
      |> TaskMaster.Tasks.create_task()

    task
  end
end
