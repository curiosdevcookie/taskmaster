defmodule TaskMaster.Repo.Migrations.AddRelationshipAvatarToUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :avatar_id, references(:avatars, type: :uuid, on_delete: :delete_all)
    end
  end
end
