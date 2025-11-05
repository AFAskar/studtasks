defmodule Studtasks.Repo do
  if Mix.env() == :prod do
    use Ecto.Repo,
      otp_app: :studtasks,
      adapter: Ecto.Adapters.Postgres
  else
    use Ecto.Repo,
      otp_app: :studtasks,
      adapter: Ecto.Adapters.SQLite3
  end
end
