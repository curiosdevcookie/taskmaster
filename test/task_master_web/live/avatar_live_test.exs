defmodule TaskMasterWeb.AvatarLiveTest do
  use TaskMasterWeb.ConnCase

  import Phoenix.LiveViewTest
  import TaskMaster.AccountsFixtures
  import TaskMaster.AvatarFixtures

  @create_attrs %{path: "some path", is_active: true}
  @update_attrs %{path: "some updated path", is_active: false}
  @invalid_attrs %{path: nil, is_active: nil}

  setup %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    %{conn: conn, user: user}
  end

  describe "Index" do
    setup [:create_avatar]

    test "lists all avatars", %{conn: conn, user: user, avatar: avatar} do
      {:ok, _index_live, html} = live(conn, ~p"/#{user.id}/avatars")

      assert html =~ "Listing Avatars"
      assert html =~ avatar.path
    end

    test "saves new avatar", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/#{user.id}/avatars")

      assert index_live |> element("a", "New Avatar") |> render_click() =~
               "New Avatar"

      assert_patch(index_live, ~p"/#{user.id}/avatars/new")

      assert index_live
             |> form("#avatar-form", avatar: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      upload = %Plug.Upload{path: "test/support/fixtures/avatar.jpg", filename: "avatar.jpg"}

      attrs = Map.merge(@create_attrs, %{avatar: upload})

      assert index_live
             |> form("#avatar-form", avatar: attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/#{user.id}/avatars")

      html = render(index_live)
      assert html =~ "Avatar created successfully"
      assert html =~ "avatar.jpg"
    end

    test "updates avatar in listing", %{conn: conn, user: user, avatar: avatar} do
      {:ok, index_live, _html} = live(conn, ~p"/#{user.id}/avatars")

      assert index_live |> element("#avatars-#{avatar.id} a", "Edit") |> render_click() =~
               "Edit Avatar"

      assert_patch(index_live, ~p"/#{user.id}/avatars/#{avatar.id}/edit")

      assert index_live
             |> form("#avatar-form", avatar: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      upload = %Plug.Upload{
        path: "test/support/fixtures/updated_avatar.jpg",
        filename: "updated_avatar.jpg"
      }

      attrs = Map.merge(@update_attrs, %{avatar: upload})

      assert index_live
             |> form("#avatar-form", avatar: attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/#{user.id}/avatars")

      html = render(index_live)
      assert html =~ "Avatar updated successfully"
      assert html =~ "updated_avatar.jpg"
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

    test "updates avatar within modal", %{conn: conn, user: user, avatar: avatar} do
      {:ok, show_live, _html} = live(conn, ~p"/#{user.id}/avatars/#{avatar.id}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Avatar"

      assert_patch(show_live, ~p"/#{user.id}/avatars/#{avatar.id}/show/edit")

      assert show_live
             |> form("#avatar-form", avatar: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      upload = %Plug.Upload{
        path: "test/support/fixtures/updated_avatar.jpg",
        filename: "updated_avatar.jpg"
      }

      attrs = Map.merge(@update_attrs, %{avatar: upload})

      assert show_live
             |> form("#avatar-form", avatar: attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/#{user.id}/avatars/#{avatar.id}")

      html = render(show_live)
      assert html =~ "Avatar updated successfully"
      assert html =~ "updated_avatar.jpg"
    end
  end
end
