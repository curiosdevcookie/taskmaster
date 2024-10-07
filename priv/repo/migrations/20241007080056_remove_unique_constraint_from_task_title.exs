defmodule TaskMaster.Repo.Migrations.RemoveUniqueConstraintFromTaskTitle do
  use Ecto.Migration

  def up do
    drop_if_exists index(:tasks, [:title])
  end

  def down do
    create unique_index(:tasks, [:title])
  end
end
