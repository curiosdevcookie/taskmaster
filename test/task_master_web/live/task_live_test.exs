defmodule TaskMasterWeb.TaskLiveTest do
  use TaskMasterWeb.ConnCase

  import Phoenix.LiveViewTest
  import TaskMaster.TasksFixtures
  import TaskMaster.AccountsFixtures
  import TaskMaster.OrganizationsFixtures
  import TaskMasterWeb.Gettext

  @create_attrs %{
    priority: :low,
    status: :open,
    description: "some description",
    title: "some title #{System.unique_integer([:positive])}",
    due_date: ~D[2024-06-28],
    duration: 42,
    indoor: true
  }
  @invalid_attrs %{
    priority: nil,
    status: nil,
    description: nil,
    title: nil,
    due_date: nil,
    duration: nil,
    indoor: false
  }

  setup %{conn: conn} do
    organization = organization_fixture()
    user = user_fixture(%{organization: organization})
    task = task_fixture(%{created_by: user.id, organization_id: organization.id})
    conn = log_in_user(conn, user)
    %{user: user, task: task, conn: conn, organization: organization}
  end

  describe "Index" do
    test "lists all tasks", %{conn: conn, user: user, task: task} do
      {:ok, _index_live, html} = live(conn, ~p"/#{user.id}/tasks")

      assert html =~ gettext("Listing Tasks")
      assert html =~ task.description
    end

    test "saves new task", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/#{user.id}/tasks")

      assert index_live |> element("a", "New Task") |> render_click() =~
               gettext("New Task")

      assert_patch(index_live, ~p"/#{user.id}/tasks/new")

      assert index_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = Map.put(@create_attrs, :created_by, user.id)

      {:ok, _, html} =
        index_live
        |> form("#task-form", task: create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/#{user.id}/tasks")

      assert html =~ "Task created successfully"
      assert html =~ "some description"
    end
  end

  describe "Show" do
    test "displays task", %{conn: conn, user: user, task: task} do
      {:ok, _show_live, html} = live(conn, ~p"/#{user.id}/tasks/#{task}")

      assert html =~ "Show Task"
      assert html =~ task.description
    end

    # test "updates task within modal", %{conn: conn, user: user, task: task} do
    #   {:ok, show_live, _html} = live(conn, ~p"/#{user.id}/tasks/#{task}")

    #   assert show_live |> element("a", "Edit") |> render_click() =~
    #            "Edit Task"

    #   assert_patch(show_live, ~p"/#{user.id}/tasks/#{task}/edit")

    #   assert show_live
    #          |> form("#task-form", task: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   update_attrs = Map.put(@update_attrs, :created_by, user.id)

    #   {:ok, _, html} =
    #     show_live
    #     |> form("#task-form", task: update_attrs)
    #     |> render_submit()
    #     |> follow_redirect(conn, ~p"/#{user.id}/tasks/#{task}")

    #   assert html =~ "Task updated successfully"
    #   assert html =~ "some updated description"
    # end
  end
end
