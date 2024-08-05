defmodule TaskMaster.OrganizationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  organizations via the `TaskMaster.Organizations` context.
  """

  def organization_fixture(attrs \\ %{}) do
    {:ok, organization} =
      attrs
      |> Enum.into(%{
        id: Ecto.UUID.generate(),
        name: "Test Organization #{System.unique_integer()}"
      })
      |> TaskMaster.Organizations.create_organization()

    organization
  end
end
