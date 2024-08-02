defmodule TaskMaster.Organizations do
  alias TaskMaster.Repo
  alias TaskMaster.Accounts.Organization

  def create_organization(attrs \\ %{}) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  def get_organization!(id), do: Repo.get!(Organization, id)

  def get_organization_by_name(name) do
    Repo.get_by(Organization, name: name)
  end

  def list_organizations do
    Repo.all(Organization)
  end
end
