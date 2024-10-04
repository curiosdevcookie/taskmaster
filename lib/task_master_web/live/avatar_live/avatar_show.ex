defmodule TaskMasterWeb.AvatarLive.AvatarShow do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> clear_flash()}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    avatar = Accounts.get_avatar!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:avatar, avatar)}
  end

  defp page_title(:show), do: gettext("Show Avatar")
  defp page_title(:edit), do: gettext("Edit Avatar")

  @impl true
  def handle_info({TaskMasterWeb.AvatarLive.AvatarComponent, {:saved, avatar}}, socket) do
    {:noreply,
     socket
     |> assign(:avatar, avatar)
     |> assign(:live_action, :show)
     |> put_flash(:info, socket.assigns.flash[:info])
     |> push_patch(to: ~p"/#{socket.assigns.current_user.id}/avatars/#{avatar}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <%= gettext("Avatar") %>
      <:actions>
        <.link
          patch={~p"/#{@current_user.id}/avatars/#{@avatar}/show/edit"}
          phx-click={JS.push_focus()}
        >
          <.button class="btn-primary"><%= gettext("Edit Avatar") %></.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-8 mb-8">
      <img src={@avatar.path} alt="Avatar" class="w-32 h-32 rounded-full object-cover mx-auto" />
    </div>

    <.back navigate={~p"/#{@current_user.id}/avatars"} />

    <.modal
      :if={@live_action == :edit}
      id="avatar-modal"
      show
      on_cancel={JS.patch(~p"/#{@current_user.id}/avatars/#{@avatar}")}
    >
      <.live_component
        module={TaskMasterWeb.AvatarLive.AvatarComponent}
        id={@avatar.id}
        title={@page_title}
        action={@live_action}
        avatar={@avatar}
        current_user={@current_user}
        patch={~p"/#{@current_user.id}/avatars/#{@avatar}"}
      />
    </.modal>
    """
  end
end
