import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :task_master, TaskMaster.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "task_master_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :task_master, TaskMasterWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "gEhQYG1SDD99SrqDFKPdd/Ear0qhHn7YrqvDZh1jTXzfxa3J6LmKBnTkKEr7u2Rl",
  server: false

# In test we don't send emails.
config :task_master, TaskMaster.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Language
config :task_master, TaskMasterWeb.Gettext, default_locale: "en"
