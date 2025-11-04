defmodule Studtasks.Repo.Migrations.CreateCourseGroups do
  use Ecto.Migration

  def change do
    create table(:course_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :creator_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:course_groups, [:user_id])

    create index(:course_groups, [:creator_id])
  end
end
