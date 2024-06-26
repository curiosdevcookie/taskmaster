defmodule TaskMaster.Accounts.UserNotifier do
  import Swoosh.Email
  import TaskMasterWeb.Gettext

  alias TaskMaster.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"TaskMaster", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, gettext("Confirmation instructions"), """

    "Hi #{user.first_name}",

    #{gettext("You can confirm your account by visiting the URL below:")}

    #{url}

    #{gettext("If you didn't create an account with us, please ignore this.")}

    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, gettext("Reset password instructions"), """

    "Hi #{user.first_name}",

    #{gettext("You can reset your password by visiting the URL below:")}

    #{url}

    #{gettext("If you didn't request this change, please ignore this.")}

    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, gettext("Update email instructions"), """

    "Hi #{user.first_name}",

    #{gettext("You can change your email by visiting the URL below:")}

    #{url}

    #{gettext("If you didn't request this change, please ignore this.")}

    """)
  end
end
