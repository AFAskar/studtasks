defmodule Studtasks.Courses do
  @moduledoc """
  The Courses context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Studtasks.Repo
  alias Studtasks.Courses.{CourseGroup, GroupMembership, Task}
  alias Studtasks.Accounts.{Scope, User}

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
    from(g in CourseGroup,
      left_join: m in Studtasks.Courses.GroupMembership,
      on: m.course_group_id == g.id and m.user_id == ^scope.user.id,
      where: not is_nil(m.id),
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
    from(g in CourseGroup,
      left_join: m in Studtasks.Courses.GroupMembership,
      on: m.course_group_id == g.id and m.user_id == ^scope.user.id,
      where: g.id == ^id and not is_nil(m.id)
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
  def group_owner?(%Scope{} = scope, %CourseGroup{} = group) do
    from(m in Studtasks.Courses.GroupMembership,
      where: m.course_group_id == ^group.id and m.user_id == ^scope.user.id and m.role == "owner",
      select: m.id
    )
    |> Repo.one()
    |> is_binary()
  end

  @doc """
  Returns true if the given scope's user is a member (or owner) of the group.
  """
  def group_member?(%Scope{} = scope, group_id) do
    from(m in Studtasks.Courses.GroupMembership,
      where: m.course_group_id == ^group_id and m.user_id == ^scope.user.id,
      select: m.id
    )
    |> Repo.one()
    |> is_binary()
  end

  @doc """
  Lists memberships for a given group with the associated users preloaded.
  """
  def list_group_memberships(group_id) do
    GroupMembership
    |> where([m], m.course_group_id == ^group_id)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Sets the role of a membership. Only the group owner can change roles.
  """
  def set_group_membership_role(%Scope{} = scope, group_id, user_id, role) do
    true = owner_membership?(scope, group_id)

    with %GroupMembership{} = mem <-
           Repo.get_by!(GroupMembership, course_group_id: group_id, user_id: user_id),
         changeset <- Ecto.Changeset.change(mem, role: role),
         {:ok, updated} <- Repo.update(changeset) do
      broadcast_course_group(scope, {:updated, get_course_group_public!(group_id)})
      {:ok, updated}
    end
  end

  @doc """
  Removes a user from the group. Only the group owner can remove members.
  The owner cannot remove themselves via membership (owners are not members).
  """
  def remove_group_member(%Scope{} = scope, group_id, user_id) do
    true = owner_membership?(scope, group_id)

    with %GroupMembership{} = mem <-
           Repo.get_by!(GroupMembership, course_group_id: group_id, user_id: user_id),
         {:ok, _} <- Repo.delete(mem) do
      broadcast_course_group(scope, {:updated, get_course_group_public!(group_id)})
      :ok
    end
  end

  @doc """
  Ensures the given user is a member of the group. Idempotent.
  """
  def ensure_group_membership(%Scope{} = scope, group_id, role \\ "member") do
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
           |> Repo.insert(),
         {:ok, _} <- ensure_group_membership(scope, course_group.id, "owner") do
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
    true = owner_or_admin_membership?(scope, course_group.id)

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
    true = owner_membership?(scope, course_group.id)

    Repo.transaction(fn ->
      from(m in Studtasks.Courses.GroupMembership, where: m.course_group_id == ^course_group.id)
      |> Repo.delete_all()

      from(t in Studtasks.Courses.Task, where: t.course_group_id == ^course_group.id)
      |> Repo.delete_all()

      {:ok, deleted} = Repo.delete(course_group)
      broadcast_course_group(scope, {:deleted, deleted})
      deleted
    end)
    |> case do
      {:ok, deleted} -> {:ok, deleted}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking course_group changes.

  ## Examples

      iex> change_course_group(scope, course_group)
      %Ecto.Changeset{data: %CourseGroup{}}

  """
  def change_course_group(%Scope{} = scope, %CourseGroup{} = course_group, attrs \\ %{}) do
    # Only enforce ownership when editing an existing record
    if is_nil(course_group.id) do
      CourseGroup.changeset(course_group, attrs, scope)
    else
      true = owner_or_admin_membership?(scope, course_group.id)
      CourseGroup.changeset(course_group, attrs, scope)
    end
  end

  @doc """
  Returns the owner user for a group, or nil if not set.
  """
  def get_group_owner_user(group_id) do
    from(m in GroupMembership,
      join: u in User,
      on: u.id == m.user_id,
      where: m.course_group_id == ^group_id and m.role == "owner",
      select: u
    )
    |> Repo.one()
  end

  defp owner_membership?(%Scope{} = scope, group_id) do
    from(m in Studtasks.Courses.GroupMembership,
      where: m.course_group_id == ^group_id and m.user_id == ^scope.user.id and m.role == "owner",
      select: m.id
    )
    |> Repo.one()
    |> is_binary()
  end

  @doc """
  Returns true if the given scope's user is an admin of the group.
  """
  def group_admin?(%Scope{} = scope, %CourseGroup{} = group) do
    from(m in Studtasks.Courses.GroupMembership,
      where: m.course_group_id == ^group.id and m.user_id == ^scope.user.id and m.role == "admin",
      select: m.id
    )
    |> Repo.one()
    |> is_binary()
  end

  defp owner_or_admin_membership?(%Scope{} = scope, group_id) do
    from(m in Studtasks.Courses.GroupMembership,
      where:
        m.course_group_id == ^group_id and m.user_id == ^scope.user.id and
          m.role in ["owner", "admin"],
      select: m.id
    )
    |> Repo.one()
    |> is_binary()
  end

  @doc """
  Subscribes to scoped notifications about any task changes.

  The broadcasted messages match the pattern:

    * {:created, %Task{}}
    * {:updated, %Task{}}
    * {:deleted, %Task{}}

  """
  def subscribe_tasks(%Scope{} = scope) do
    # Subscribe to all group task topics the user is a member of
    list_course_groups(scope)
    |> Enum.each(fn g -> Phoenix.PubSub.subscribe(Studtasks.PubSub, "group:#{g.id}:tasks") end)
  end

  @doc """
  Subscribe to task updates for a specific group.
  """
  def subscribe_group_tasks(group_id) do
    Phoenix.PubSub.subscribe(Studtasks.PubSub, "group:#{group_id}:tasks")
  end

  defp broadcast_task(%Scope{} = _scope, message) do
    # Broadcast to the group topic so all members receive real-time updates
    case message do
      {_, %Task{course_group_id: group_id}} when not is_nil(group_id) ->
        Phoenix.PubSub.broadcast(Studtasks.PubSub, "group:#{group_id}:tasks", message)

      _ ->
        :ok
    end
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
    true = group_member?(scope, course_group_id)

    from(t in Task,
      where: t.course_group_id == ^course_group_id,
      preload: [:assignee, :creator, :children, :parent],
      order_by: [asc: t.position, desc: t.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns a limited list of tasks assigned to the current user across all groups,
  ordered by priority and due date.

  Defaults to 5 items.
  """
  def list_assigned_tasks(%Scope{} = scope, limit \\ 5) when is_integer(limit) do
    from(t in Task,
      join: m in GroupMembership,
      on: m.course_group_id == t.course_group_id and m.user_id == ^scope.user.id,
      where: t.assignee_id == ^scope.user.id,
      preload: [:assignee, :creator, :children, :course_group],
      order_by: [desc: t.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns a limited list of most recently created tasks for the current user across all groups.

  Defaults to 5 items.
  """
  def list_recent_tasks(%Scope{} = scope, limit \\ 5) when is_integer(limit) do
    from(t in Task,
      join: m in GroupMembership,
      on: m.course_group_id == t.course_group_id and m.user_id == ^scope.user.id,
      preload: [:assignee, :creator, :children, :course_group],
      order_by: [desc: t.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns all tasks assigned to the current user across all groups, newest first.
  """
  def list_assigned_tasks_all(%Scope{} = scope) do
    from(t in Task,
      join: m in GroupMembership,
      on: m.course_group_id == t.course_group_id and m.user_id == ^scope.user.id,
      where: t.assignee_id == ^scope.user.id,
      preload: [:assignee, :creator, :children, :course_group],
      order_by: [desc: t.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns all tasks for the current user across all groups, newest first.
  """
  def list_recent_tasks_all(%Scope{} = scope) do
    from(t in Task,
      join: m in GroupMembership,
      on: m.course_group_id == t.course_group_id and m.user_id == ^scope.user.id,
      preload: [:assignee, :creator, :children, :course_group],
      order_by: [desc: t.inserted_at]
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
    from(t in Task,
      join: m in GroupMembership,
      on: m.course_group_id == t.course_group_id and m.user_id == ^scope.user.id,
      where: t.id == ^id
    )
    |> Repo.one!()
  end

  @doc """
  Gets a single task within a course group.

  Raises `Ecto.NoResultsError` if not found or not owned by user.
  """
  def get_task_in_group!(%Scope{} = scope, id, course_group_id) do
    from(t in Task,
      join: m in GroupMembership,
      on: m.course_group_id == t.course_group_id and m.user_id == ^scope.user.id,
      where: t.id == ^id and t.course_group_id == ^course_group_id
    )
    |> Repo.one!()
    |> Repo.preload([:assignee, :children, :parent])
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
    changeset =
      %Task{}
      |> Task.changeset(attrs, scope)
      |> validate_parent_same_group()
      |> validate_parent_depth()

    group_id = Ecto.Changeset.get_field(changeset, :course_group_id)

    # Only enforce membership when we actually have a group_id present in the changeset
    if not is_nil(group_id), do: true = group_member?(scope, group_id)

    case Repo.insert(changeset) do
      {:ok, task = %Task{}} ->
        broadcast_task(scope, {:created, task})
        {:ok, task}

      {:error, %Ecto.Changeset{} = cs} ->
        {:error, cs}
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
    true = group_member?(scope, task.course_group_id)

    with {:ok, task = %Task{}} <-
           task
           |> Task.changeset(attrs, scope)
           |> validate_parent_same_group()
           |> validate_parent_depth()
           |> Repo.update() do
      broadcast_task(scope, {:updated, task})
      {:ok, task}
    end
  end

  @doc """
  Reorders tasks within a column by updating their positions.

  Takes a list of task IDs in the desired order and updates their positions accordingly.
  """
  def reorder_tasks(%Scope{} = scope, task_ids, status, course_group_id) when is_list(task_ids) do
    true = group_member?(scope, course_group_id)

    # Build updates for each task with its new position
    updates =
      task_ids
      |> Enum.with_index()
      |> Enum.map(fn {id, index} ->
        from(t in Task,
          where: t.id == ^id and t.course_group_id == ^course_group_id and t.status == ^status
        )
        |> Repo.update_all(set: [position: index])
      end)

    # Return :ok if all updates succeeded
    if Enum.all?(updates, fn {count, _} -> count > 0 end) do
      :ok
    else
      {:error, :invalid_reorder}
    end
  end

  @doc """
  Atomically moves a task to a new column (status) and sets its position.
  This combines status update and reordering in a single transaction to avoid race conditions.
  """
  def move_task_to_column(
        %Scope{} = scope,
        task_id,
        new_status,
        task_ids_in_order,
        course_group_id
      ) do
    true = group_member?(scope, course_group_id)

    multi =
      Multi.new()
      # Step 1: Update the moved task's status and position atomically
      |> Multi.run(:update_moved_task, fn repo, _changes ->
        # Find the position of the moved task in the new ordering
        new_position =
          Enum.find_index(task_ids_in_order, fn id -> to_string(id) == to_string(task_id) end)

        if is_nil(new_position) do
          {:error, :task_not_in_order}
        else
          query =
            from(t in Task,
              where: t.id == ^task_id and t.course_group_id == ^course_group_id
            )

          case repo.update_all(query, set: [status: new_status, position: new_position]) do
            {1, _} -> {:ok, new_position}
            {0, _} -> {:error, :task_not_found}
            _ -> {:error, :unexpected_count}
          end
        end
      end)
      # Step 2: Update positions for all other tasks in the new column
      |> Multi.run(:reorder_column, fn repo, %{update_moved_task: _moved_position} ->
        # Update all tasks in the new status column (except the moved one) with their correct positions
        results =
          task_ids_in_order
          |> Enum.with_index()
          |> Enum.reject(fn {id, _idx} -> to_string(id) == to_string(task_id) end)
          |> Enum.map(fn {id, index} ->
            query =
              from(t in Task,
                where:
                  t.id == ^id and t.course_group_id == ^course_group_id and
                    t.status == ^new_status
              )

            repo.update_all(query, set: [position: index])
          end)

        {:ok, results}
      end)

    case Repo.transaction(multi) do
      {:ok, _} ->
        # Broadcast the update so other clients see the change
        task = get_task!(scope, task_id)
        broadcast_task(scope, {:updated, task})
        :ok

      {:error, _step, reason, _changes} ->
        {:error, reason}
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
    true = group_member?(scope, task.course_group_id)
    # Deletion strategy: we do NOT cascade delete children. Instead we
    # orphan them by setting their parent_id to nil prior to deleting the
    # parent task. This preserves child tasks and avoids accidental loss
    # of work items.

    multi =
      Multi.new()
      |> Multi.run(:orphan_children, fn repo, _changes ->
        # Orphan all children by nullifying their parent_id in a single statement.
        children_query = from(t in Task, where: t.parent_id == ^task.id)

        {count, _} = repo.update_all(children_query, set: [parent_id: nil])
        {:ok, count}
      end)
      |> Multi.delete(:delete_task, task)

    case Repo.transaction(multi) do
      {:ok, %{delete_task: task}} ->
        broadcast_task(scope, {:deleted, task})
        {:ok, task}

      {:error, _op, reason, _changes} ->
        {:error, reason}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(scope, task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Scope{} = scope, %Task{} = task, attrs \\ %{}) do
    true = is_nil(task.id) or group_member?(scope, task.course_group_id)

    Task.changeset(task, attrs, scope)
  end

  @doc """
  Returns all root tasks (tasks without a parent) for the given course group.
  Includes their immediate children.
  """
  def list_root_tasks(%Scope{} = scope, course_group_id) do
    true = group_member?(scope, course_group_id)

    from(t in Task,
      where: t.course_group_id == ^course_group_id and is_nil(t.parent_id),
      preload: [:children, :assignee, :creator]
    )
    |> Repo.all()
  end

  @doc """
  Returns child tasks for a given parent task id (only immediate children).
  Ensures membership in the parent's course group.
  """
  def list_child_tasks(%Scope{} = scope, parent_id) do
    parent = get_task!(scope, parent_id)

    from(t in Task,
      where: t.parent_id == ^parent.id,
      preload: [:children, :assignee, :creator]
    )
    |> Repo.all()
  end

  @doc """
  Returns a simple task tree for a course group (one level of children preloaded).
  """
  def task_tree(%Scope{} = scope, course_group_id) do
    list_root_tasks(scope, course_group_id)
  end

  # Private helpers
  defp validate_parent_same_group(%Ecto.Changeset{} = changeset) do
    parent_id = Ecto.Changeset.get_field(changeset, :parent_id)
    course_group_id = Ecto.Changeset.get_field(changeset, :course_group_id)
    task_id = changeset.data.id

    cond do
      is_nil(parent_id) ->
        changeset

      task_id && parent_id == task_id ->
        Ecto.Changeset.add_error(changeset, :parent_id, "cannot reference itself")

      true ->
        case Repo.get(Task, parent_id) do
          nil ->
            Ecto.Changeset.add_error(changeset, :parent_id, "parent does not exist")

          %Task{course_group_id: ^course_group_id} ->
            changeset

          %Task{} ->
            Ecto.Changeset.add_error(
              changeset,
              :parent_id,
              "parent must belong to the same course group"
            )
        end
    end
  end

  # Ensures there is only one level of parent-child depth.
  # If the chosen parent itself has a parent, we reject the change.
  defp validate_parent_depth(%Ecto.Changeset{} = changeset) do
    parent_id = Ecto.Changeset.get_field(changeset, :parent_id)

    cond do
      is_nil(parent_id) ->
        changeset

      true ->
        case Repo.get(Task, parent_id) do
          nil ->
            # Let the foreign_key_constraint handle non-existent parent normally; keep explicit error for clarity.
            Ecto.Changeset.add_error(changeset, :parent_id, "parent does not exist")

          %Task{parent_id: grandparent_id} when not is_nil(grandparent_id) ->
            Ecto.Changeset.add_error(
              changeset,
              :parent_id,
              "parent task already has a parent; only one level allowed"
            )

          _ ->
            changeset
        end
    end
  end
end
