defmodule TaskMasterWeb.AvatarLive.AvatarIndex do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Accounts

  @impl true
  def mount(_params, _session, socket) do
    avatars = Accounts.list_avatars(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "Your Avatar")
     |> assign(:avatar, List.first(avatars))
     |> stream(:avatars, avatars)}
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

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= gettext("Listing Avatars") %>
    </.header>

    <.table
      id="avatars"
      rows={@streams.avatars}
      row_click={fn {_id, avatar} -> JS.navigate(~p"/#{@current_user.id}/avatars/#{avatar}") end}
    >
      <:col :let={{_id, avatar}}>
        <img src={avatar.path} alt="Avatar" style="width: 50px; height: 50px;" />
      </:col>

      <:action :let={{_id, avatar}}>
        <div class="sr-only">
          <.link navigate={~p"/#{@current_user.id}/avatars/#{avatar}"}><%= gettext("Show") %></.link>
        </div>
        <.link patch={~p"/#{@current_user.id}/avatars/#{avatar}/edit"}><%= gettext("Edit") %></.link>
      </:action>
      <:action :let={{id, avatar}}>
        <.link
          phx-click={JS.push("delete", value: %{id: avatar.id}) |> hide("##{id}")}
          data-confirm={gettext("Are you sure?")}
          class="btn-danger"
        >
          <%= gettext("Delete") %>
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="avatar-modal"
      show
      on_cancel={JS.patch(~p"/#{@current_user.id}/avatars")}
    >
      <.live_component
        module={TaskMasterWeb.AvatarLive.AvatarComponent}
        id={@avatar.id || :new}
        title={@page_title}
        action={@live_action}
        avatar={@avatar}
        current_user={@current_user}
        patch={~p"/#{@current_user.id}/avatars"}
      />
    </.modal>
    """
  end
end
