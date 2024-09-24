defmodule TaskMaster.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :first_name, :citext
      add :last_name, :citext
      add :company, :citext
      add :area_of_expertise, :citext
      add :email, :citext
      add :phone, :string
      add :mobile, :string
      add :street, :string
      add :street_number, :string
      add :city, :string
      add :notes, :text

      timestamps()
    end
  end
end
