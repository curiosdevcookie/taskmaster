defmodule TaskMasterWeb.UserConfirmationInstructionsLive do
  use TaskMasterWeb, :live_view

  alias TaskMaster.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm sm:mt-10 sm:p-8 flex flex-col gap-10">
      <section class="mx-auto max-w-sm">
        <.header class="text-center">
          <%= gettext("Confirm Account") %><span> 🎉</span>
          <h3 class="text-center text-xl text-gray-500 mt-10">
            <%= gettext("If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly.") %>
          </h3>
        </.header>
      </section>
      <section>
        <.footer class="text-center">
          <%= gettext("No email received?") %>
          <:subtitle><%= gettext("We'll send a new confirmation link to your inbox") %></:subtitle>
        </.footer>

        <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
          <div class="flex flex-col gap-4">
            <.input field={@form[:email]} type="email" placeholder="Email" required />
            <.button class="btn-primary place-self-end" phx-disable-with="Sending...">
              <%= gettext("Resend") %>
            </.button>
          </div>
        </.simple_form>
      </section>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      gettext(
        "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."
      )

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/users/confirm")}
  end
end
