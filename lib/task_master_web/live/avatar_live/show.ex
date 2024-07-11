defmodule TaskMasterWeb.AvatarLive.Show do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:avatar, Accounts.get_avatar!(id))}
  end

  defp page_title(:show), do: "Show Avatar"
  defp page_title(:edit), do: "Edit Avatar"
end
