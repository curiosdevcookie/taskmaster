defmodule TaskMaster.AvatarFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskMaster.Accounts` context.
  """

  alias TaskMaster.Accounts

  def avatar_fixture(attrs \\ %{})

  def avatar_fixture(%TaskMaster.Accounts.User{} = user) do
    avatar_fixture(%{user_id: user.id})
  end

  def avatar_fixture(attrs) do
    {:ok, avatar} =
      attrs
      |> Enum.into(%{
        path: "some path",
        is_active: true,
        user_id: attrs[:user_id] || TaskMaster.AccountsFixtures.user_fixture().id
      })
      |> Accounts.create_avatar()

    avatar
  end

  def create_avatar(%{user: user}) do
    avatar = avatar_fixture(user)
    %{avatar: avatar}
  end
end
