defmodule TaskMaster.Repo.Migrations.AddStarsToUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :stars, :integer, default: 0
    end
  end
end
