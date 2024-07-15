defmodule TaskMaster.Repo.Migrations.AddDefaultAvatar do
  use Ecto.Migration
  import Ecto.Query

  def up do
    execute """
    INSERT INTO avatars (id, user_id, path, inserted_at, updated_at)
    SELECT gen_random_uuid(), id, '/uploads/default_avatar.png', NOW(), NOW()
    FROM users
    WHERE id NOT IN (SELECT user_id FROM avatars)
    """
  end

  def down do
    execute "DELETE FROM avatars WHERE path = '/uploads/default_avatar.png'"
  end
end
