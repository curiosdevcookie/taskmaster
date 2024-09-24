defmodule TaskMaster.ContactsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskMaster.Contacts` context.
  """

  @doc """
  Generate a contact.
  """
  def contact_fixture(attrs \\ %{}) do
    {:ok, contact} =
      attrs
      |> Enum.into(%{

      })
      |> TaskMaster.Contacts.create_contact()

    contact
  end
end
