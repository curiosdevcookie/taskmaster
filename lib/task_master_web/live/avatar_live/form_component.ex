defmodule TaskMasterWeb.AvatarLive.FormComponent do
  use TaskMasterWeb, :live_component

  alias TaskMaster.Accounts

  @impl true
  def update(%{avatar: avatar} = assigns, socket) do
    changeset = Accounts.change_avatar(avatar)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def handle_event("validate", %{"avatar" => avatar_params}, socket) do
    changeset =
      socket.assigns.avatar
      |> Accounts.change_avatar(avatar_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"avatar" => avatar_params}, socket) do
    save_avatar(socket, socket.assigns.action, avatar_params)
  end

  defp save_avatar(socket, :edit, avatar_params) do
    case Accounts.update_avatar(socket.assigns.avatar, avatar_params) do
      {:ok, _avatar} ->
        {:noreply,
         socket
         |> put_flash(:info, "Avatar updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_avatar(socket, :new, avatar_params) do
    case upload_avatar(socket, avatar_params) do
      {:ok, avatar} ->
        {:noreply,
         socket
         |> put_flash(:info, "Avatar created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp upload_avatar(socket, avatar_params) do
    consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
      dest = Path.join("priv/static/uploads", Path.basename(path))
      File.cp!(path, dest)
      {:ok, "/uploads/#{Path.basename(dest)}"}
    end)
    |> case do
      [url] ->
        Accounts.create_avatar(Map.put(avatar_params, "path", url))

      _ ->
        {:error, %Ecto.Changeset{}}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>test</div>
    """
  end
end
