defmodule TaskMaster.TasksTest do
  use TaskMaster.DataCase

  alias TaskMaster.Tasks

  describe "tasks" do
    alias TaskMaster.Tasks.Task

    import TaskMaster.TasksFixtures

    @invalid_attrs %{
      priority: nil,
      status: nil,
      description: nil,
      title: nil,
      due_date: nil,
      duration: nil,
      completed_at: nil,
      indoor: nil,
      created_by: nil
    }

    test "list_tasks/0 returns all tasks" do
      task = task_fixture()
      assert Tasks.list_tasks() == [task]
    end

    test "get_task!/1 returns the task with given id" do
      task = task_fixture()
      assert Tasks.get_task!(task.id) == task
    end

    test "create_task/1 with valid data creates a task" do
      user = AccountsFixtures.user_fixture()

      valid_attrs = %{
        priority: :low,
        status: :open,
        description: "some description",
        title: "some title",
        due_date: ~D[2024-06-28],
        duration: 42,
        completed_at: ~N[2024-06-28 13:17:00],
        indoor: true,
        created_by: user.id
      }

      assert {:ok, %Task{} = task} = Tasks.create_task(valid_attrs)
      assert task.priority == :low
      assert task.status == :open
      assert task.description == "some description"
      assert task.title == "some title"
      assert task.due_date == ~D[2024-06-28]
      assert task.duration == 42
      assert task.completed_at == ~N[2024-06-28 13:17:00]
      assert task.indoor == true
    end

    test "create_task/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasks.create_task(@invalid_attrs)
    end

    test "update_task/2 with valid data updates the task" do
      task = task_fixture()

      update_attrs = %{
        priority: :medium,
        status: :progressing,
        description: "some updated description",
        title: "some updated title",
        due_date: ~D[2024-06-29],
        duration: 43,
        completed_at: ~N[2024-06-29 13:17:00],
        indoor: false
      }

      assert {:ok, %Task{} = task} = Tasks.update_task(task, update_attrs)
      assert task.priority == :medium
      assert task.status == :progressing
      assert task.description == "some updated description"
      assert task.title == "some updated title"
      assert task.due_date == ~D[2024-06-29]
      assert task.duration == 43
      assert task.completed_at == ~N[2024-06-29 13:17:00]
      assert task.indoor == false
    end

    test "update_task/2 with invalid data returns error changeset" do
      task = task_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.update_task(task, @invalid_attrs)
      assert task == Tasks.get_task!(task.id)
    end

    test "delete_task/1 deletes the task" do
      task = task_fixture()
      assert {:ok, %Task{}} = Tasks.delete_task(task)
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(task.id) end
    end

    test "change_task/1 returns a task changeset" do
      task = task_fixture()
      assert %Ecto.Changeset{} = Tasks.change_task(task)
    end
  end
end
