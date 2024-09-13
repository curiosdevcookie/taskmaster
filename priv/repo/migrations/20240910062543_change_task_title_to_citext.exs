defmodule TaskMaster.Repo.Migrations.ChangeTaskTitleToCitext do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      modify :title, :citext
    end
  end
end
