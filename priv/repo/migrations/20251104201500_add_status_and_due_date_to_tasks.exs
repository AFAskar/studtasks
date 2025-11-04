defmodule Studtasks.Repo.Migrations.AddStatusAndDueDateToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :status, :string, null: false, default: "backlog"
      add :due_date, :date
    end

    create index(:tasks, [:due_date])
  end
end
