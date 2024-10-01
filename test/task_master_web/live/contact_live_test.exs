defmodule TaskMasterWeb.ContactLiveTest do
  use TaskMasterWeb.ConnCase

  import Phoenix.LiveViewTest
  import TaskMaster.ContactsFixtures
  import TaskMaster.OrganizationsFixtures
  import TaskMaster.AccountsFixtures

  @create_attrs %{
    first_name: "John",
    last_name: "Doe",
    company: "ACME Corp",
    area_of_expertise: "Software Development",
    email: "john@example.com",
    phone: "123-456-7890",
    mobile: "987-654-3210",
    street: "Main St",
    street_number: "123",
    postal_code: "12345",
    city: "Anytown",
    notes: "Some notes"
  }

  @invalid_attrs %{company: nil, area_of_expertise: nil}

  setup do
    %{id: organization_id} = organization = organization_fixture()
    user = user_fixture(%{organization_id: organization_id})
    contact = contact_fixture(%{organization_id: organization_id})
    conn = log_in_user(build_conn(), user)
    %{conn: conn, organization: organization, user: user, contact: contact}
  end

  describe "Index" do
    test "lists all contacts", %{conn: conn, user: user} do
      {:ok, _index_live, html} = live(conn, ~p"/#{user.id}/contacts")

      assert html =~ "Listing Contacts"
    end

    test "saves new contact", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/#{user.id}/contacts")

      assert index_live |> element("a", "New Contact") |> render_click() =~
               "New Contact"

      assert_patch(index_live, ~p"/#{user.id}/contacts/new")

      assert index_live
             |> form("#contact-form", contact: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#contact-form", contact: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/#{user.id}/contacts")

      html = render(index_live)
      assert html =~ "Contact created successfully"
    end

    test "updates contact in listing", %{conn: conn, user: user, contact: contact} do
      {:ok, index_live, _html} = live(conn, ~p"/#{user.id}/contacts")

      assert index_live |> element("a[href$='/edit']") |> render_click()

      assert_patch(index_live, ~p"/#{user.id}/contacts/#{contact}/edit")

      assert index_live
             |> form("#contact-form", contact: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"
    end

    test "deletes contact in listing", %{conn: conn, user: user, contact: contact} do
      {:ok, _index_live, html} = live(conn, ~p"/#{user.id}/contacts")
      assert html =~ contact.company
      assert html =~ contact.area_of_expertise
    end
  end

  describe "Show" do
    test "displays contact", %{conn: conn, user: user, contact: contact} do
      {:ok, _show_live, html} = live(conn, ~p"/#{user.id}/contacts/#{contact}")

      assert html =~ "Show Contact"
    end

    test "updates contact within modal", %{conn: conn, user: user, contact: contact} do
      {:ok, show_live, _html} = live(conn, ~p"/#{user.id}/contacts/#{contact}")

      assert show_live |> element("a[href$='/edit']") |> render_click()
      assert_patch(show_live, ~p"/#{user.id}/contacts/#{contact}/show/edit")

      assert show_live
             |> form("#contact-form", contact: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"
    end
  end
end
