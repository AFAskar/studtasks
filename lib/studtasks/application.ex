defmodule Studtasks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      StudtasksWeb.Telemetry,
      Studtasks.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:studtasks, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:studtasks, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Studtasks.PubSub},
      # Start a worker by calling: Studtasks.Worker.start_link(arg)
      # {Studtasks.Worker, arg},
      # Start to serve requests, typically the last entry
      StudtasksWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Studtasks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StudtasksWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
