defmodule Studtasks.Courses.CourseGroup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "course_groups" do
    field :name, :string
    field :description, :string
    field :creator_id, :binary_id
    field :user_id, :binary_id

    belongs_to :creator, Studtasks.Accounts.User, define_field: false, foreign_key: :creator_id
    belongs_to :owner, Studtasks.Accounts.User, define_field: false, foreign_key: :user_id
    has_many :tasks, Studtasks.Courses.Task
    has_many :group_memberships, Studtasks.Courses.GroupMembership
    many_to_many :users, Studtasks.Accounts.User,
      join_through: Studtasks.Courses.GroupMembership,
      join_keys: [course_group_id: :id, user_id: :id]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(course_group, attrs, user_scope) do
    course_group
    |> cast(attrs, [:name, :description, :creator_id])
    |> validate_required([:name, :description])
    |> maybe_put_creator(user_scope)
    |> put_change(:user_id, user_scope.user.id)
  end

  defp maybe_put_creator(changeset, user_scope) do
    case get_field(changeset, :creator_id) do
      nil -> put_change(changeset, :creator_id, user_scope.user.id)
      _ -> changeset
    end
  end
end
