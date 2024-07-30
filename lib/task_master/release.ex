defmodule TaskMaster.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :task_master

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def truncate_tables do
    load_app()

    for repo <- repos() do
      truncate_repo(repo)
    end
  end

  defp truncate_repo(repo) do
    IO.puts("Truncating tables for #{@app}")

    # Add all your table names here
    tables = ~w(users tasks)

    Ecto.Adapters.SQL.query!(repo, "SET session_replication_role = 'replica';", [])

    for table <- tables do
      Ecto.Adapters.SQL.query!(repo, "TRUNCATE TABLE #{table} CASCADE;", [])
      IO.puts("Truncated table: #{table}")
    end

    Ecto.Adapters.SQL.query!(repo, "SET session_replication_role = 'origin';", [])

    IO.puts("Truncation complete for #{@app}")
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
