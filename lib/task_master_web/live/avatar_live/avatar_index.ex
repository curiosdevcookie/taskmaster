defmodule TaskMasterWeb.AvatarLive.AvatarIndex do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Accounts
  alias TaskMaster.Accounts.Avatar

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    avatars = Accounts.list_avatars(current_user)

    {:ok,
     socket
     |> stream(:avatars, avatars)
     |> assign(:avatar, %Avatar{user_id: current_user.id})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Avatar")
    |> assign(:avatar, Accounts.get_avatar!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Avatar")
    |> assign(:avatar, %Avatar{user_id: socket.assigns.current_user.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Avatars")
    |> assign(:avatar, nil)
  end

  @impl true
  def handle_info({TaskMasterWeb.AvatarLive.AvatarComponent, {:saved, avatar}}, socket) do
    {:noreply, stream_insert(socket, :avatars, avatar)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    avatar = Accounts.get_avatar!(id)
    {:ok, _} = Accounts.delete_avatar(avatar)

    {:noreply, stream_delete(socket, :avatars, avatar)}
  end
end
