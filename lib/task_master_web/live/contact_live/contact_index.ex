defmodule TaskMasterWeb.ContactLive.ContactIndex do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Contacts
  alias TaskMaster.Contacts.Contact

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user |> dbg()
    contacts = Contacts.list_contacts(current_user.organization_id)

    socket =
      socket
      |> assign(:page_title, "Listing Contacts")
      |> assign(:contact, nil)
      |> assign(:live_action, :index)
      |> assign(:current_user, current_user)
      |> stream(:contacts, contacts)
      |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Contact")
    |> assign(:contact, Contacts.get_contact!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Contact")
    |> assign(:contact, %Contact{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Contacts")
    |> assign(:contact, nil)
  end

  @impl true
  def handle_info({TaskMasterWeb.ContactLive.FormComponent, {:saved, contact}}, socket) do
    {:noreply, stream_insert(socket, :contacts, contact)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    contact = Contacts.get_contact!(id)
    {:ok, _} = Contacts.delete_contact(contact)

    {:noreply, stream_delete(socket, :contacts, contact)}
  end
end
