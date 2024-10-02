defmodule TaskMasterWeb.ContactLive.ContactIndex do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Contacts
  alias TaskMaster.Contacts.Contact

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    contacts = Contacts.list_contacts(current_user.organization_id)

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
    socket
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(:contact, Contacts.get_contact!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(:contact, %Contact{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Contacts")
    |> assign(:contact, nil)
  end

  @impl true
  def handle_info({TaskMasterWeb.ContactLive.ContactComponent, {:saved, contact}}, socket) do
    {:noreply, stream_insert(socket, :contacts, contact)}
  end

  @impl true

  def handle_event("delete", %{"id" => id}, socket) do
  contact = Contacts.get_contact!(id)
  case Contacts.delete_contact(contact) do
    {:ok, _} ->
      socket
      # |> put_flash(:info, gettext("Contact deleted successfully"))
      |> stream_delete(:contacts, contact)
      |> noreply()

    {:error, _reason} ->
      socket
      |> put_flash(:error, gettext("Failed to delete contact"))
      |> noreply()
  end
end

  defp page_title(:show), do: gettext("Show Contact")
  defp page_title(:new), do: gettext("New Contact")
  defp page_title(:edit), do: gettext("Edit Contact")
end
