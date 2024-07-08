defmodule TaskMaster.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskMaster.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def unique_user_nick_name, do: "user#{System.unique_integer()}"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      id: Ecto.UUID.generate(),
      email: unique_user_email(),
      first_name: "John",
      last_name: "Doe",
      password: valid_user_password(),
      nick_name: unique_user_nick_name()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        id: Ecto.UUID.generate(),
        email: unique_user_email(),
        password: valid_user_password(),
        first_name: "Test",
        last_name: "User",
        nick_name: unique_user_nick_name()
      })
      |> TaskMaster.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
