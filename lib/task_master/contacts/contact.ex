defmodule TaskMaster.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset
  import TaskMasterWeb.Gettext

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type :binary_id
  schema "contacts" do
    field :first_name, :string
    field :last_name, :string
    field :company, :string
    field :area_of_expertise, :string
    field :email, :string
    field :phone, :string
    field :mobile, :string
    field :street, :string
    field :street_number, :string
    field :postal_code, :string
    field :city, :string
    field :notes, :string

    belongs_to :organization, TaskMaster.Accounts.Organization, type: :binary_id

    timestamps()
  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [
      :first_name,
      :last_name,
      :company,
      :area_of_expertise,
      :email,
      :phone,
      :mobile,
      :street,
      :street_number,
      :postal_code,
      :city,
      :notes,
      :organization_id
    ])
    |> validate_required([:company, :area_of_expertise, :organization_id])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
        message: gettext("must have the @ sign and no spaces")
      )
    |> validate_length(:phone, max: 20)
    |> validate_length(:mobile, max: 20)
    |> validate_length(:postal_code, max: 10)
    |> unique_constraint([:email, :organization_id])
  end
end
