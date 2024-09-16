defmodule TaskMasterWeb.AvatarLive.AvatarComponent do
  use TaskMasterWeb, :live_component

  alias TaskMaster.Accounts

  @impl true
  def update(%{avatar: avatar} = assigns, socket) do
    changeset = Accounts.change_avatar(avatar)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))
     |> assign(:uploaded_avatar, nil)
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl true
  def handle_event("save", params, socket) do
    avatar_params = params["avatar"] || %{}
    save_avatar(socket, socket.assigns.action, avatar_params)
  end

  defp save_avatar(socket, action, avatar_params) do
    IO.puts("Saving avatar: #{inspect(action)}, #{inspect(avatar_params)}")

    case uploaded_entries(socket, :avatar) do
      [] ->
        {:noreply, put_flash(socket, :error, "No file uploaded")}

      _entries ->
        uploads_dir = Application.fetch_env!(:task_master, :upload_path)

        File.mkdir_p!(uploads_dir)

        uploaded_files =
          consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
            ext = Path.extname(entry.client_name)
            file_name = "#{socket.assigns.current_user.id}_avatar#{ext}"
            dest = Path.join(uploads_dir, file_name)
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
            {:noreply, socket |> put_flash(:info, avatar_action_message(action))}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
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

      <.simple_form
        for={@form}
        id="avatar-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-2 ">
          <div class="flex flex-col gap-4">
            <%= if @avatar.path do %>
              <div class="flex flex-col gap-4">
                <label class="block text-sm font-medium text-gray-700">
                  <%= gettext("Current Avatar") %>
                </label>
                <img
                  src={@avatar.path}
                  alt={gettext("Current Avatar")}
                  class="w-32 h-32 object-cover rounded-full"
                />
              </div>
            <% end %>
            <.live_file_input upload={@uploads.avatar} class="mt-1" />
          </div>

          <div class="flex flex-col gap-4">
            <label class="block text-sm font-medium text-gray-700">
              <%= gettext("New Avatar") %>
            </label>

            <%= for entry <- @uploads.avatar.entries do %>
              <.live_img_preview entry={entry} class="w-32 h-32 object-cover rounded-full" />
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                class="text-sm text-red-600 text-left mt-2"
                phx-target={@myself}
              >
                <%= gettext("Cancel") %>
              </button>
            <% end %>
          </div>
        </div>

        <:actions>
          <.button class="btn-primary" phx-disable-with={gettext("Saving...")}>
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
