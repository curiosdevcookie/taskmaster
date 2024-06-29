defmodule TaskMaster.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :priority, Ecto.Enum, values: [:low, :medium, :high], default: :medium
    field :status, Ecto.Enum, values: [:open, :progressing, :completed], default: :open
    field :description, :string
    field :title, :string
    field :due_date, :date
    field :duration, :integer
    field :completed_at, :naive_datetime
    field :indoor, :boolean, default: false

    belongs_to :creator, TaskMaster.Accounts.User, foreign_key: :created_by
    belongs_to :parent_task, TaskMaster.Tasks.Task, foreign_key: :parent_task_id

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :title,
      :description,
      :due_date,
      :status,
      :duration,
      :completed_at,
      :priority,
      :indoor
    ])
    |> validate_required([
      :title,
      :status,
      :priority,
      :indoor
    ])
  end
end
