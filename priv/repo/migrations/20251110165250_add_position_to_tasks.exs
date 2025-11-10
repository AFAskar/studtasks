defmodule Studtasks.Repo.Migrations.AddPositionToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :position, :integer, default: 0
    end

    create index(:tasks, [:course_group_id, :status, :position])
  end
end
