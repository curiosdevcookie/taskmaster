defmodule TaskMaster.Repo.Migrations.AddTaskPartcicipations do
  use Ecto.Migration

  def change do
    create table(:task_participations, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all)
      add :task_id, references(:tasks, type: :uuid, on_delete: :delete_all)
      timestamps()
    end

    create unique_index(:task_participations, [:user_id, :task_id])
  end
end
