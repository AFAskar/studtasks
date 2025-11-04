defmodule Studtasks.Repo.Migrations.CreateGroupMemberships do
  use Ecto.Migration

  def change do
    create table(:group_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :course_group_id, references(:course_groups, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:group_memberships, [:user_id])
    create index(:group_memberships, [:course_group_id])
    create unique_index(:group_memberships, [:course_group_id, :user_id])
  end
end
