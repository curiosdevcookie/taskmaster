defmodule TaskMaster.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskMaster.Tasks` context.
  """

  import TaskMaster.AccountsFixtures
  import TaskMaster.OrganizationsFixtures

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    organization = attrs[:organization] || organization_fixture()
    user = attrs[:user] || user_fixture(%{organization: organization})

    valid_attrs = %{
      title: "some title #{System.unique_integer([:positive])}",
      description: "some description",
      due_date: ~D[2024-06-28],
      status: :open,
      priority: :medium,
      indoor: false,
      created_by: user.id,
      organization_id: organization.id
    }

    {:ok, task} =
      attrs
      |> Enum.into(valid_attrs)
      |> TaskMaster.Tasks.create_task()

    task
  end
end
