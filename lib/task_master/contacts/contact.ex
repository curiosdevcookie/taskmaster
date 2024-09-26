defmodule TaskMaster.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset

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

    belongs_to :organization, TaskMaster.Contacts.Organization, type: :binary_id

    timestamps()
  end

  @doc false
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
    |> validate_required([])
  end
end
