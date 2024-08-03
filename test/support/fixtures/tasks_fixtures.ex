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
    user = attrs[:user] || user_fixture(%{organization_id: organization.id})

    valid_attrs = %{
      "title" => "Task #{System.unique_integer([:positive])}",
      "description" => "some description",
      "due_date" => Date.utc_today(),
      "status" => "open",
      "priority" => "medium",
      "indoor" => false,
      "created_by" => user.id,
      "organization_id" => organization.id
    }

    attrs = for {key, val} <- attrs, into: %{}, do: {to_string(key), val}
    attrs = Map.merge(valid_attrs, attrs)

    {:ok, task} = TaskMaster.Tasks.create_task(attrs, [], attrs["organization_id"])

    TaskMaster.Tasks.get_task!(task.id, attrs["organization_id"])
  end
end
