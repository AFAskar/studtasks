defmodule Studtasks.Repo.Migrations.AddPriorityToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :priority, :string, null: false, default: "medium"
    end

    # Backfill existing rows if needed (defaults handle it)
  end
end
