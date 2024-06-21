defmodule TaskMaster.Repo do
  use Ecto.Repo,
    otp_app: :task_master,
    adapter: Ecto.Adapters.Postgres
end
