defmodule Studtasks.Courses.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tasks" do
    field :name, :string
    field :description, :string
    field :course_group_id, :binary_id
    field :creator_id, :binary_id
    field :assignee_id, :binary_id
    field :parent_id, :binary_id
    field :user_id, :binary_id
    field :status, :string, default: "backlog"
    field :due_date, :date

    belongs_to :course_group, Studtasks.Courses.CourseGroup, define_field: false
    belongs_to :creator, Studtasks.Accounts.User, define_field: false, foreign_key: :creator_id
    belongs_to :assignee, Studtasks.Accounts.User, define_field: false, foreign_key: :assignee_id
    belongs_to :parent, __MODULE__, define_field: false, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs, user_scope) do
    task
    |> cast(attrs, [:name, :description, :course_group_id, :creator_id, :assignee_id, :parent_id])
    |> validate_required([:name, :description, :course_group_id])
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
