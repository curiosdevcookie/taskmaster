defmodule TaskMasterWeb.TaskLiveTest do
  use TaskMasterWeb.ConnCase

  import Phoenix.LiveViewTest
  import TaskMaster.TasksFixtures
  import TaskMaster.AccountsFixtures
  import TaskMaster.OrganizationsFixtures
  import TaskMasterWeb.Gettext

  @invalid_attrs %{title: nil, description: nil}
  @create_attrs %{
    title: "some title",
    description: "some description",
    status: :open,
    priority: :medium,
    indoor: false
  }

  setup do
    %{id: organization_id} = organization = organization_fixture()
    user = user_fixture(%{organization_id: organization_id})
    task = task_fixture(%{created_by: user.id, organization: organization})
    conn = log_in_user(build_conn(), user)
    %{conn: conn, organization: organization, user: user, task: task}
  end

  describe "Index" do
    test "lists all tasks", %{conn: conn, user: user, task: task} do
      {:ok, _index_live, html} = live(conn, ~p"/#{user.id}/tasks")

      assert html =~ gettext("Listing Tasks")
      assert html =~ task.description
    end

    test "displays task", %{conn: conn, user: user, task: task} do
      {:ok, _show_live, html} = live(conn, ~p"/#{user.id}/tasks/#{task}")

      assert html =~ gettext("Show Task")
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

      create_attrs =
        @create_attrs
        |> Map.put(:created_by, user.id)

      {:ok, _, html} =
        index_live
        |> form("#task-form", task: create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/#{user.id}/tasks")

      assert html =~ gettext("Task created successfully")
      assert html =~ gettext("New Task")
    end
  end

  describe "Show" do
    test "displays task", %{conn: conn, user: user, task: task} do
      {:ok, _show_live, html} = live(conn, ~p"/#{user.id}/tasks/#{task}")

      assert html =~ "Show Task"
      assert html =~ task.description
    end
  end
end
