defmodule Studtasks.Repo.Migrations.AddPreferredTaskViewToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :preferred_task_view, :string, null: false, default: "list"
    end
  end
end
