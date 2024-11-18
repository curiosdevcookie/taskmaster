defmodule TaskMasterWeb.UserSettingsLive do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Accounts
  alias TaskMasterWeb.AvatarLive.AvatarComponent

  @impl true
  def render(assigns) do
    ~H"""
    <.header class="text-center">
      <%= gettext("Account Settings") %>
      <:subtitle>
        <%= gettext("Manage your account avatar, email address and password settings") %>
      </:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.live_component
          module={AvatarComponent}
          id="avatar"
          title=""
          action={if @avatar.id, do: :edit, else: :new}
          avatar={@current_user.avatar || %TaskMaster.Accounts.Avatar{}}
          current_user={@current_user}
        />
      </div>

      <div>
      <.simple_form
      for={@nick_name_form}
      id="nick_name_form"
      phx-submit="update_nick_name"
      phx-change="validate_nick_name"
    >
      <.input field={@nick_name_form[:nick_name]} type="text" label={gettext("Nickname")} required />
          <:actions>
            <.button class="btn-primary" phx-disable-with="Updating...">
              <%= gettext("Change Nickname") %>
            </.button>
          </:actions>
        </.simple_form>
      </div>

      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label={gettext("Email")} required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label={gettext("Current password")}
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button class="btn-primary" phx-disable-with="Changing...">
              <%= gettext("Change Email") %>
            </.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input
            field={@password_form[:password]}
            type="password"
            label={gettext("New password")}
            required
          />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label={gettext("Confirm new password")}
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label={gettext("Current password")}
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button class="btn-primary" phx-disable-with="Changing...">
              <%= gettext("Change Password") %>
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, gettext("Email changed successfully."))

        :error ->
          put_flash(socket, :error, gettext("Email change link is invalid or it has expired."))
      end

    {:ok, push_navigate(socket, to: ~p"/#{socket.assigns.current_user}/users/settings")}
  end

  def mount(%{"current_user" => current_user_id}, _session, socket) do
    try do
      user = Accounts.get_user!(current_user_id)
      email_changeset = Accounts.change_user_email(user)
      password_changeset = Accounts.change_user_password(user)
      nick_name_changeset = Accounts.change_user_nick_name(user)

      avatar = Accounts.get_active_avatar(user) || %TaskMaster.Accounts.Avatar{}

      socket =
        socket
        |> assign(:current_user, user)
        |> assign(:current_password, nil)
        |> assign(:email_form_current_password, nil)
        |> assign(:current_email, user.email)
        |> assign(:email_form, to_form(email_changeset))
        |> assign(:password_form, to_form(password_changeset))
        |> assign(:avatar, avatar)
        |> assign(:trigger_submit, false)
        |> assign(:nick_name_form, to_form(nick_name_changeset))

      {:ok, socket}
    rescue
      Ecto.NoResultsError ->
        socket =
          socket
          |> put_flash(:error, gettext("User not found"))
          |> redirect(to: ~p"/")

        {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, gettext("Edit User Settings"))
  end

  defp apply_action(socket, :confirm_email, %{"token" => token}) do
    current_user = socket.assigns.current_user

    case Accounts.update_user_email(current_user, token) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Email changed successfully."))
         |> push_navigate(to: ~p"/#{current_user.id}/users/settings")}

      :error ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Email change link is invalid or it has expired."))}
    end
  end

  @impl true
  def handle_info({AvatarComponent, {:saved, avatar}}, socket) do
    {:noreply, assign(socket, :avatar, avatar)}
  end

  @impl true
  def handle_event("update_avatar", %{"avatar" => avatar_params}, socket) do
    current_user = socket.assigns.current_user

    case Accounts.create_user_avatar(current_user, avatar_params) do
      {:ok, _avatar} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Avatar updated successfully"))
         |> push_navigate(to: ~p"/#{current_user.id}/users/settings")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, avatar_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  @impl true
  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/#{user}/users/settings/confirm_email/#{&1}")
        )

        info = gettext("A link to confirm your email change has been sent to the new address.")
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  @impl true
  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  @impl true
  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate_nick_name", params, socket) do
    %{"user" => user_params} = params
    nick_name_form =
      socket.assigns.current_user
      |> Accounts.change_user_nick_name(user_params)
      |> Map.put(:action, :validate)
      |> to_form()
      {:noreply, assign(socket, nick_name_form: nick_name_form)}
    end

  @impl true
  def handle_event("update_nick_name", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_nick_name(user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Nickname updated successfully"))
         |> push_navigate(to: ~p"/#{user.id}/users/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, nick_name_form: to_form(changeset))}
    end
  end
end
