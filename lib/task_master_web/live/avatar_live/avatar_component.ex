defmodule TaskMasterWeb.AvatarLive.AvatarComponent do
  use TaskMasterWeb, :live_component

  alias TaskMaster.Accounts
  alias TaskMaster.Accounts.Avatar

  @impl true
  @impl true
  def update(%{avatar: avatar} = assigns, socket) do
    changeset = Accounts.change_avatar(avatar)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    avatar_params = params["avatar"] || %{}

    changeset =
      %Avatar{}
      |> Avatar.avatar_changeset(avatar_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", params, socket) do
    avatar_params = params["avatar"] || %{}
    save_avatar(socket, socket.assigns.action, avatar_params)
  end

  defp save_avatar(socket, action, avatar_params) do
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        ext = Path.extname(entry.client_name)
        file_name = "#{socket.assigns.current_user.id}_avatar#{ext}"
        dest = Path.join("priv/static/uploads", file_name)
        File.cp!(path, dest)
        {:ok, "/uploads/#{file_name}"}
      end)

    avatar_params =
      avatar_params
      |> Map.put("path", List.first(uploaded_files))
      |> Map.put("is_active", true)
      |> Map.put("user_id", socket.assigns.current_user.id)

    case action do
      :edit -> Accounts.update_avatar(socket.assigns.avatar, avatar_params)
      :new -> Accounts.create_avatar(avatar_params)
    end
    |> case do
      {:ok, avatar} ->
        notify_parent({:saved, avatar})

        {:noreply,
         socket
         |> put_flash(:info, avatar_action_message(action))
         |> push_patch(to: ~p"/#{socket.assigns.current_user.id}/users/settings")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp avatar_action_message(:edit), do: gettext("Avatar updated successfully")
  defp avatar_action_message(:new), do: gettext("Avatar created successfully")

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <%= if @avatar.path do %>
        <div class="m-4">
          <img src={@avatar.path} alt="Current Avatar" class="w-32 h-32 object-cover rounded-full" />
        </div>
      <% end %>

      <.simple_form
        for={@form}
        id="avatar-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.live_file_input upload={@uploads.avatar} />

        <:actions>
          <.button phx-disable-with={gettext("Saving...")}><%= gettext("Save") %></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
