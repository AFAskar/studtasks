defmodule Studtasks.Courses do
  @moduledoc """
  The Courses context.
  """

  import Ecto.Query, warn: false
  alias Studtasks.Repo

  alias Studtasks.Courses.CourseGroup
  alias Studtasks.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any course_group changes.

  The broadcasted messages match the pattern:

    * {:created, %CourseGroup{}}
    * {:updated, %CourseGroup{}}
    * {:deleted, %CourseGroup{}}

  """
  def subscribe_course_groups(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Studtasks.PubSub, "user:#{key}:course_groups")
  end

  defp broadcast_course_group(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Studtasks.PubSub, "user:#{key}:course_groups", message)
  end

  @doc """
  Returns the list of course_groups.

  ## Examples

      iex> list_course_groups(scope)
      [%CourseGroup{}, ...]

  """
  def list_course_groups(%Scope{} = scope) do
    import Ecto.Query

    from(g in CourseGroup,
      left_join: m in Studtasks.Courses.GroupMembership,
      on: m.course_group_id == g.id and m.user_id == ^scope.user.id,
      where: g.user_id == ^scope.user.id or not is_nil(m.id),
      distinct: true
    )
    |> Repo.all()
  end

  @doc """
  Gets a single course_group.

  Raises `Ecto.NoResultsError` if the Course group does not exist.

  ## Examples

      iex> get_course_group!(scope, 123)
      %CourseGroup{}

      iex> get_course_group!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_course_group!(%Scope{} = scope, id) do
    import Ecto.Query

    from(g in CourseGroup,
      left_join: m in Studtasks.Courses.GroupMembership,
      on: m.course_group_id == g.id and m.user_id == ^scope.user.id,
      where: g.id == ^id and (g.user_id == ^scope.user.id or not is_nil(m.id))
    )
    |> Repo.one!()
  end

  @doc """
  Gets a course_group by id without membership enforcement.

  Raises if not found. Use this for pages that may be visible to non-members,
  while guarding any mutations separately.
  """
  def get_course_group_public!(id) do
    Repo.get!(CourseGroup, id)
  end

  @doc """
  Returns true if the given scope's user is the owner of the group.
  """
  def group_owner?(%Scope{} = scope, %CourseGroup{} = group), do: group.user_id == scope.user.id

  @doc """
  Returns true if the given scope's user is a member (or owner) of the group.
  """
  def group_member?(%Scope{} = scope, group_id) do
    import Ecto.Query

    owner? =
      from(g in CourseGroup,
        where: g.id == ^group_id and g.user_id == ^scope.user.id,
        select: g.id
      )
      |> Repo.one()

    if owner? do
      true
    else
      from(m in Studtasks.Courses.GroupMembership,
        where: m.course_group_id == ^group_id and m.user_id == ^scope.user.id,
        select: m.id
      )
      |> Repo.one()
      |> is_binary()
    end
  end

  @doc """
  Lists memberships for a given group with the associated users preloaded.
  """
  def list_group_memberships(group_id) do
    alias Studtasks.Courses.GroupMembership

    GroupMembership
    |> where([m], m.course_group_id == ^group_id)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Sets the role of a membership. Only the group owner can change roles.
  """
  def set_group_membership_role(%Scope{} = scope, group_id, user_id, role) do
    alias Studtasks.Courses.GroupMembership

    group = get_course_group_public!(group_id)
    true = group.user_id == scope.user.id

    with %GroupMembership{} = mem <-
           Repo.get_by!(GroupMembership, course_group_id: group_id, user_id: user_id),
         changeset <- Ecto.Changeset.change(mem, role: role),
         {:ok, updated} <- Repo.update(changeset) do
      broadcast_course_group(scope, {:updated, group})
      {:ok, updated}
    end
  end

  @doc """
  Removes a user from the group. Only the group owner can remove members.
  The owner cannot remove themselves via membership (owners are not members).
  """
  def remove_group_member(%Scope{} = scope, group_id, user_id) do
    alias Studtasks.Courses.GroupMembership

    group = get_course_group_public!(group_id)
    true = group.user_id == scope.user.id

    with %GroupMembership{} = mem <-
           Repo.get_by!(GroupMembership, course_group_id: group_id, user_id: user_id),
         {:ok, _} <- Repo.delete(mem) do
      broadcast_course_group(scope, {:updated, group})
      :ok
    end
  end

  @doc """
  Ensures the given user is a member of the group. Idempotent.
  """
  def ensure_group_membership(%Scope{} = scope, group_id, role \\ "member") do
    alias Studtasks.Courses.GroupMembership

    %GroupMembership{}
    |> GroupMembership.changeset(%{
      user_id: scope.user.id,
      course_group_id: group_id,
      role: role
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:course_group_id, :user_id])
  end

  @doc """
  Creates a course_group.

  ## Examples

      iex> create_course_group(scope, %{field: value})
      {:ok, %CourseGroup{}}

      iex> create_course_group(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_course_group(%Scope{} = scope, attrs) do
    with {:ok, course_group = %CourseGroup{}} <-
           %CourseGroup{}
           |> CourseGroup.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_course_group(scope, {:created, course_group})
      {:ok, course_group}
    end
  end

  @doc """
  Updates a course_group.

  ## Examples

      iex> update_course_group(scope, course_group, %{field: new_value})
      {:ok, %CourseGroup{}}

      iex> update_course_group(scope, course_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_course_group(%Scope{} = scope, %CourseGroup{} = course_group, attrs) do
    true = course_group.user_id == scope.user.id

    with {:ok, course_group = %CourseGroup{}} <-
           course_group
           |> CourseGroup.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_course_group(scope, {:updated, course_group})
      {:ok, course_group}
    end
  end

  @doc """
  Deletes a course_group.

  ## Examples

      iex> delete_course_group(scope, course_group)
      {:ok, %CourseGroup{}}

      iex> delete_course_group(scope, course_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_course_group(%Scope{} = scope, %CourseGroup{} = course_group) do
    true = course_group.user_id == scope.user.id

    with {:ok, course_group = %CourseGroup{}} <-
           Repo.delete(course_group) do
      broadcast_course_group(scope, {:deleted, course_group})
      {:ok, course_group}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking course_group changes.

  ## Examples

      iex> change_course_group(scope, course_group)
      %Ecto.Changeset{data: %CourseGroup{}}

  """
  def change_course_group(%Scope{} = scope, %CourseGroup{} = course_group, attrs \\ %{}) do
    true = course_group.user_id == scope.user.id

    CourseGroup.changeset(course_group, attrs, scope)
  end

  alias Studtasks.Courses.Task
  alias Studtasks.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any task changes.

  The broadcasted messages match the pattern:

    * {:created, %Task{}}
    * {:updated, %Task{}}
    * {:deleted, %Task{}}

  """
  def subscribe_tasks(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Studtasks.PubSub, "user:#{key}:tasks")
  end

  defp broadcast_task(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Studtasks.PubSub, "user:#{key}:tasks", message)
  end

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks(scope)
      [%Task{}, ...]

  """
  def list_tasks(%Scope{} = scope) do
    Repo.all_by(Task, user_id: scope.user.id)
  end

  @doc """
  Returns the list of tasks for a given course group.

  ## Examples

      iex> list_group_tasks(scope, group_id)
      [%Task{}, ...]

  """
  def list_group_tasks(%Scope{} = scope, course_group_id) do
    from(t in Task,
      where: t.user_id == ^scope.user.id and t.course_group_id == ^course_group_id,
      preload: [:assignee, :creator, :children]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(scope, 123)
      %Task{}

      iex> get_task!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(%Scope{} = scope, id) do
    Repo.get_by!(Task, id: id, user_id: scope.user.id)
  end

  @doc """
  Gets a single task within a course group.

  Raises `Ecto.NoResultsError` if not found or not owned by user.
  """
  def get_task_in_group!(%Scope{} = scope, id, course_group_id) do
    Repo.get_by!(Task, id: id, user_id: scope.user.id, course_group_id: course_group_id)
  end

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(scope, %{field: value})
      {:ok, %Task{}}

      iex> create_task(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(%Scope{} = scope, attrs) do
    with {:ok, task = %Task{}} <-
           %Task{}
           |> Task.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_task(scope, {:created, task})
      {:ok, task}
    end
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(scope, task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(scope, task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Scope{} = scope, %Task{} = task, attrs) do
    true = task.user_id == scope.user.id

    with {:ok, task = %Task{}} <-
           task
           |> Task.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_task(scope, {:updated, task})
      {:ok, task}
    end
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(scope, task)
      {:ok, %Task{}}

      iex> delete_task(scope, task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Scope{} = scope, %Task{} = task) do
    true = task.user_id == scope.user.id

    with {:ok, task = %Task{}} <-
           Repo.delete(task) do
      broadcast_task(scope, {:deleted, task})
      {:ok, task}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(scope, task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Scope{} = scope, %Task{} = task, attrs \\ %{}) do
    true = task.user_id == scope.user.id

    Task.changeset(task, attrs, scope)
  end
end
