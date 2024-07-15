defmodule TaskMasterWeb.AvatarLiveTest do
  use TaskMasterWeb.ConnCase

  import Phoenix.LiveViewTest
  import TaskMaster.AccountsFixtures
  import TaskMaster.AvatarFixtures
  import TaskMasterWeb.Gettext

  setup %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    %{conn: conn, user: user}
  end

  describe "Index" do
    setup [:create_avatar]

    test "lists all avatars", %{conn: conn, user: user, avatar: avatar} do
      {:ok, _index_live, html} = live(conn, ~p"/#{user.id}/avatars")

      assert html =~ gettext("Listing Avatars")
      assert html =~ avatar.path
    end

    test "deletes avatar in listing", %{conn: conn, user: user, avatar: avatar} do
      {:ok, index_live, _html} = live(conn, ~p"/#{user.id}/avatars")

      assert index_live |> element("#avatars-#{avatar.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#avatars-#{avatar.id}")
    end
  end

  describe "Show" do
    setup [:create_avatar]

    test "displays avatar", %{conn: conn, user: user, avatar: avatar} do
      {:ok, _show_live, html} = live(conn, ~p"/#{user.id}/avatars/#{avatar.id}")

      assert html =~ "Show Avatar"
      assert html =~ avatar.path
    end
  end
end
