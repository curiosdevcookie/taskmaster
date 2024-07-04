defmodule TaskMasterWeb.TaskLiveTest do
  use TaskMasterWeb.ConnCase

  import Phoenix.LiveViewTest
  import TaskMaster.TasksFixtures
  import TaskMaster.AccountsFixtures
  import TaskMasterWeb.Gettext

  @create_attrs %{
    priority: :low,
    status: :open,
    description: "some description",
    title: "some title",
    due_date: "2024-06-28",
    duration: 42,
    completed_at: "2024-06-28T13:17:00",
    indoor: true
  }
  @update_attrs %{
    priority: :medium,
    status: :progressing,
    description: "some updated description",
    title: "some updated title",
    due_date: "2024-06-29",
    duration: 43,
    completed_at: "2024-06-29T13:17:00",
    indoor: false
  }
  @invalid_attrs %{
    priority: nil,
    status: nil,
    description: nil,
    title: nil,
    due_date: nil,
    duration: nil,
    completed_at: nil,
    indoor: false
  }

  setup do
    user = user_fixture()
    %{user: user}
  end

  defp create_task(%{user: user}) do
    task = task_fixture(user_id: user.id)
    %{task: task}
  end

  describe "Index" do
    setup [:create_task]

    test "lists all tasks", %{conn: conn, user: user, task: task} do
      {:ok, _index_live, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/#{user.id}/tasks")

      assert html =~ "Listing Tasks"
      assert html =~ task.description
    end

    test "saves new task", %{conn: conn, user: user} do
      {:ok, index_live, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/#{user.id}/tasks")

      assert index_live |> element("a", "New Task") |> render_click() =~
               "New Task"

      assert_patch(index_live, ~p"/#{user.id}/tasks/new")

      assert index_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#task-form", task: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/#{user.id}/tasks")

      html = render(index_live)
      assert html =~ "Task created successfully"
      assert html =~ "some description"
    end
  end

  describe "Show" do
    setup [:create_task]

    test "displays task", %{conn: conn, task: task, user: user} do
      {:ok, _show_live, html} = live(conn, ~p"/#{user.id}/tasks/#{task}")

      assert html =~ gettext("Show Task")
      assert html =~ task.description
    end

    test "updates task within modal", %{conn: conn, task: task, user: user} do
      {:ok, show_live, _html} = live(conn, ~p"/#{user.id}/tasks/#{task}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Task"

      assert_patch(show_live, ~p"/#{user.id}/tasks/#{task}/show/edit")

      assert show_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#task-form", task: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/#{user.id}/tasks/#{task}")

      html = render(show_live)
      assert html =~ "Task updated successfully"
      assert html =~ "some updated description"
    end
  end
end
