defmodule TaskMasterWeb.AvatarLive.AvatarIndex do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Accounts
  alias TaskMaster.Accounts.Avatar

  @impl true
  def mount(_params, _session, socket) do
    avatar = Accounts.get_active_avatar(socket.assigns.current_user)
    {:ok, assign(socket, :avatar, avatar)}
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
    |> assign(:avatar, %Accounts.Avatar{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Avatar")
    |> assign(:avatar, socket.assigns.avatar)
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
