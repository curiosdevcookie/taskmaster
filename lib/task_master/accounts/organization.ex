defmodule TaskMaster.Accounts.Organization do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "organizations" do
    field :name, :string
    has_many :users, TaskMaster.Accounts.User
    has_many :contacts, TaskMaster.Contacts.Contact

    timestamps()
  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def for_org(query, org_id) when is_binary(org_id) do
    query
    |> where([t], t.organization_id == ^org_id)
  end

  def for_org_with_preload(query, org_id) when is_binary(org_id) do
    query
    |> for_org(org_id)
    |> preload(:organization)
  end
end
