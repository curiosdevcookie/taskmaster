defmodule TaskMaster.Repo.Migrations.CreateOrganizationsAndUpdateUsers do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :citext, null: false

      timestamps()
    end

    create unique_index(:organizations, [:name])

    alter table(:users) do
      add :organization_id, references(:organizations, type: :uuid)
    end

    create index(:users, [:organization_id])

    alter table(:tasks) do
      add :organization_id, references(:organizations, type: :uuid, on_delete: :delete_all)
    end

    create index(:tasks, [:organization_id])
  end
end
