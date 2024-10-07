defmodule TaskMasterWeb.UserRegistrationLive do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Accounts
  alias TaskMaster.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        <%= gettext("Register for an account") %>
        <:subtitle>
          <%= gettext("Already registered?") %>
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            ➜ <%= gettext("Log in") %>
          </.link>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error>
        <.input
          field={@form[:organization_name]}
          type="text"
          label={gettext("Organization name")}
          required
          phx-debounce="blur"
        />
        <.input field={@form[:first_name]} type="text" label={gettext("First name")} required />
        <.input field={@form[:last_name]} type="text" label={gettext("Last name")} required />
        <.input field={@form[:nick_name]} type="text" label={gettext("Nick name")} required />
        <.input field={@form[:email]} type="email" label={gettext("Email")} required />
        <.input field={@form[:password]} type="password" label={gettext("Password")} required />

        <:actions>
          <.button
            phx-disable-with="Creating account..."
            class="btn-primary"
            disabled={not @form.source.valid?}
          >
            <%= gettext("Create account") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket
    |> assign_form(changeset)
    |> assign(trigger_submit: false)
    |> assign(check_errors: false)
    |> ok()
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    socket
    |> assign_form(changeset)
    |> noreply()
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(:info, gettext("User created successfully."))
         |> redirect(to: ~p"/users/confirm")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
