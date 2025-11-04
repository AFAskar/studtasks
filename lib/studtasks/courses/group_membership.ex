defmodule Studtasks.Courses.GroupMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "group_memberships" do
    field :role, :string

    belongs_to :user, Studtasks.Accounts.User
    belongs_to :course_group, Studtasks.Courses.CourseGroup

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group_membership, attrs) do
    group_membership
    |> cast(attrs, [:role, :user_id, :course_group_id])
    |> validate_required([:role, :user_id, :course_group_id])
  end
end
