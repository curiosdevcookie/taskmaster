defmodule TaskMaster.TasksTest do
  use TaskMaster.DataCase

  alias TaskMaster.Tasks
  alias TaskMaster.Tasks.Task
  import TaskMaster.TasksFixtures
  import TaskMaster.AccountsFixtures
  import TaskMaster.OrganizationsFixtures

  setup do
    organization = organization_fixture()
    user = user_fixture(%{organization_id: organization.id})
    %{organization: organization, user: user}
  end

  @valid_attrs %{
    "priority" => "medium",
    "status" => "open",
    "description" => "some description",
    "title" => "some title",
    "due_date" => "2024-06-28",
    "duration" => 42,
    "indoor" => false
  }
  @invalid_attrs %{
    "priority" => nil,
    "status" => nil,
    "description" => nil,
    "title" => nil,
    "due_date" => nil,
    "duration" => nil,
    "indoor" => nil
  }

  describe "tasks" do
    test "list_tasks/1 returns all tasks", %{organization: organization} do
      task = task_fixture(%{"organization_id" => organization.id})
      assert [returned_task] = Tasks.list_tasks(organization.id)
      assert returned_task.id == task.id
    end

    test "get_task!/2 returns the task with given id", %{organization: organization} do
      task = task_fixture(%{"organization_id" => organization.id})
      assert returned_task = Tasks.get_task!(task.id, organization.id)
      assert returned_task.id == task.id
    end

    test "create_task/3 with valid data creates a task", %{organization: organization, user: user} do
      valid_attrs =
        Map.merge(@valid_attrs, %{"created_by" => user.id, "organization_id" => organization.id})

      assert {:ok, %Task{} = task} = Tasks.create_task(valid_attrs, [], organization.id)
      assert task.priority == String.to_existing_atom(valid_attrs["priority"])
      assert task.status == String.to_existing_atom(valid_attrs["status"])
      assert task.description == valid_attrs["description"]
      assert task.title == valid_attrs["title"]
      assert task.due_date == Date.from_iso8601!(valid_attrs["due_date"])
      assert task.duration == valid_attrs["duration"]
      assert task.indoor == valid_attrs["indoor"]
      assert task.created_by == user.id
      assert task.organization_id == organization.id
    end

    @invalid_attrs %{
      title: nil,
      status: nil,
      priority: nil,
      indoor: nil,
      created_by: nil,
      organization_id: nil
    }

    test "update_task/4 with invalid data returns error tuple and doesn't change the task" do
      organization = organization_fixture()
      task = task_fixture(%{organization: organization})

      assert {:error, {:error, %Ecto.Changeset{}}} =
               Tasks.update_task(task, @invalid_attrs, [], organization.id)

      updated_task = Tasks.get_task!(task.id, organization.id)
      assert updated_task == task
    end

    test "delete_task/2 deletes the task", %{organization: organization} do
      task = task_fixture(%{"organization_id" => organization.id})
      assert {:ok, %Task{}} = Tasks.delete_task(task, organization.id)
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(task.id, organization.id) end
    end

    test "change_task/1 returns a task changeset", %{organization: organization} do
      task = task_fixture(%{organization_id: organization.id})
      assert %Ecto.Changeset{} = Tasks.change_task(task)
    end
  end
end
