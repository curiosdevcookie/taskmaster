defmodule TaskMaster.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    # Create ENUM types if they don't exist
    execute """
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
        CREATE TYPE task_status AS ENUM ('open', 'progressing', 'completed');
      END IF;
    END
    $$;
    """

    execute """
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_priority') THEN
        CREATE TYPE task_priority AS ENUM ('low', 'medium', 'high');
      END IF;
    END
    $$;
    """

    create table(:tasks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :due_date, :date
      add :status, :task_status, null: false, default: "open"
      add :duration, :integer
      add :completed_at, :naive_datetime
      add :priority, :task_priority, null: false, default: "medium"
      add :indoor, :boolean, default: false
      add :created_by, references(:users, type: :uuid, on_delete: :nilify_all), null: false
      add :parent_task_id, references(:tasks, type: :uuid, on_delete: :nilify_all)

      timestamps()
    end

    create index(:tasks, [:created_by])
    create index(:tasks, [:parent_task_id])
    create unique_index(:tasks, [:title])
  end

  def down do
    drop table(:tasks)
    execute "DROP TYPE IF EXISTS task_status"
    execute "DROP TYPE IF EXISTS task_priority"
  end
end
