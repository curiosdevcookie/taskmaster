defmodule TaskMasterWeb.AvatarLive.AvatarShow do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Accounts

  @impl true
  def mount(%{"current_user" => current_user_id} = _params, _session, socket) do
    current_user = TaskMaster.Accounts.get_user!(current_user_id)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> stream(:avatars, TaskMaster.Accounts.list_avatars(current_user))
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
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
