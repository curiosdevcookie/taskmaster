defmodule TaskMaster.Accounts.Avatar do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "avatars" do
    field :path, :string

    belongs_to :user, TaskMaster.Accounts.User

    timestamps()
  end

  @doc false
  def avatar_changeset(avatar, attrs \\ %{}) do
    avatar
    |> cast(attrs, [:path, :user_id, :is_active])
    |> validate_required([:path, :user_id, :is_active])
    |> foreign_key_constraint(:user_id)
    |> validate_inclusion(:is_active, [true, false])
  end
end
