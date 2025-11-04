defmodule Studtasks.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :course_group_id, references(:course_groups, on_delete: :nothing, type: :binary_id)
      add :creator_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :assignee_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :parent_id, references(:tasks, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:user_id])

    create index(:tasks, [:course_group_id])
    create index(:tasks, [:creator_id])
    create index(:tasks, [:assignee_id])
    create index(:tasks, [:parent_id])
  end
end
