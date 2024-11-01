defmodule TaskMaster.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tasks" do
    field :title, :string
    field :priority, Ecto.Enum, values: [:low, :medium, :high], default: :medium
    field :status, Ecto.Enum, values: [:open, :progressing, :completed], default: :open
    field :description, :string
    field :due_date, :date
    field :duration, :integer
    field :completed_at, :naive_datetime
    field :indoor, :boolean, default: false

    belongs_to :creator, TaskMaster.Accounts.User, foreign_key: :created_by
    belongs_to :parent_task, TaskMaster.Tasks.Task, foreign_key: :parent_task_id
    belongs_to :organization, TaskMaster.Accounts.Organization, type: :binary_id

    has_many :task_participations, TaskMaster.Tasks.TaskParticipation
    has_many :participants, through: [:task_participations, :user]

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :title,
      :description,
      :due_date,
      :duration,
      :priority,
      :status,
      :indoor,
      :created_by,
      :organization_id,
      :parent_task_id
    ])
    |> validate_required([:title, :status, :priority, :indoor, :created_by, :organization_id])
  end

  def for_org(query, org_id) when is_binary(org_id) do
    query
    |> where([t], t.organization_id == ^org_id)
  end
end
