defmodule Studtasks.Repo.Migrations.RemoveOwnerFromCourseGroups do
  use Ecto.Migration

  def change do
    drop_if_exists index(:course_groups, [:user_id])

    alter table(:course_groups) do
      remove :user_id
    end
  end
end
