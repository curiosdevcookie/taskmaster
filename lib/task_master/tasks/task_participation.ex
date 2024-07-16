defmodule TaskMaster.Tasks.TaskParticipation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "task_participations" do
    belongs_to :user, TaskMaster.Accounts.User
    belongs_to :task, TaskMaster.Tasks.Task

    timestamps()
  end

  def changeset(task_participation, attrs) do
    task_participation
    |> cast(attrs, [:user_id, :task_id])
    |> validate_required([:user_id, :task_id])
    |> unique_constraint([:user_id, :task_id])
  end
end
