import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :argon2_elixir, t_cost: 1, m_cost: 8

# Configure your database (PostgreSQL in test)
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :studtasks, Studtasks.Repo,
  username: System.get_env("PGUSER", "nadhm"),
  password: System.get_env("PGPASSWORD", "password"),
  hostname: System.get_env("PGTESTHOST", "localhost"),
  database: System.get_env("PGDBNAME", "nadhm"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :studtasks, StudtasksWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "HCH4CjyyDCZTWmAeVXvUACwA3XUfaSKppcqjtHYhw8BGBpaGNZf7AJJaQwhmoNVC",
  server: false

# In test we don't send emails
config :studtasks, Studtasks.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
