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
    Repo.all_by(CourseGroup, user_id: scope.user.id)
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
    Repo.get_by!(CourseGroup, id: id, user_id: scope.user.id)
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
      where: t.user_id == ^scope.user.id and t.course_group_id == ^course_group_id
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
