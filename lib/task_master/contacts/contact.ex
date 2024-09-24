defmodule TaskMaster.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset

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
    field :city, :string
    field :notes, :string

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [])
    |> validate_required([])
  end
end
