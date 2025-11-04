defmodule Studtasks.Repo.Migrations.AddStatusAndDueDateToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :status, :string, null: false, default: "backlog"
      add :due_date, :date
    end

    # Optional: index for common queries
    create index(:tasks, [:course_group_id, :status])
    create index(:tasks, [:assignee_id])
    create index(:tasks, [:due_date])
  end
end
