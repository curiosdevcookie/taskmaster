defmodule TaskMasterWeb.ContactLive.ContactShow do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Contacts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:contact, Contacts.get_contact!(id))}
  end

  defp page_title(:show), do: gettext("Show Contact")
  defp page_title(:edit), do: gettext("Edit Contact")
end
