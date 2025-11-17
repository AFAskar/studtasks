defmodule Studtasks.CoursesTest do
  use Studtasks.DataCase

  alias Studtasks.Courses

  describe "course_groups" do
    alias Studtasks.Courses.CourseGroup

    import Studtasks.AccountsFixtures, only: [user_scope_fixture: 0]
    import Studtasks.CoursesFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_course_groups/1 returns all scoped course_groups" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      course_group = course_group_fixture(scope)
      other_course_group = course_group_fixture(other_scope)
      assert Courses.list_course_groups(scope) == [course_group]
      assert Courses.list_course_groups(other_scope) == [other_course_group]
    end

    test "get_course_group!/2 returns the course_group with given id" do
      scope = user_scope_fixture()
      course_group = course_group_fixture(scope)
      other_scope = user_scope_fixture()
      assert Courses.get_course_group!(scope, course_group.id) == course_group

      assert_raise Ecto.NoResultsError, fn ->
        Courses.get_course_group!(other_scope, course_group.id)
      end
    end

    test "create_course_group/2 with valid data creates a course_group" do
      valid_attrs = %{name: "some name", description: "some description"}
      scope = user_scope_fixture()

      assert {:ok, %CourseGroup{} = course_group} =
               Courses.create_course_group(scope, valid_attrs)

      assert course_group.name == "some name"
      assert course_group.description == "some description"
      assert Courses.group_owner?(scope, course_group)
    end

    test "create_course_group/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Courses.create_course_group(scope, @invalid_attrs)
    end

    test "update_course_group/3 with valid data updates the course_group" do
      scope = user_scope_fixture()
      course_group = course_group_fixture(scope)
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %CourseGroup{} = course_group} =
               Courses.update_course_group(scope, course_group, update_attrs)

      assert course_group.name == "some updated name"
      assert course_group.description == "some updated description"
    end

    test "update_course_group/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      course_group = course_group_fixture(scope)

      assert_raise MatchError, fn ->
        Courses.update_course_group(other_scope, course_group, %{})
      end
    end

    test "update_course_group/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      course_group = course_group_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Courses.update_course_group(scope, course_group, @invalid_attrs)

      assert course_group == Courses.get_course_group!(scope, course_group.id)
    end

    test "delete_course_group/2 deletes the course_group" do
      scope = user_scope_fixture()
      course_group = course_group_fixture(scope)
      assert {:ok, %CourseGroup{}} = Courses.delete_course_group(scope, course_group)

      assert_raise Ecto.NoResultsError, fn ->
        Courses.get_course_group!(scope, course_group.id)
      end
    end

    test "delete_course_group/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      course_group = course_group_fixture(scope)
      assert_raise MatchError, fn -> Courses.delete_course_group(other_scope, course_group) end
    end

    test "change_course_group/2 returns a course_group changeset" do
      scope = user_scope_fixture()
      course_group = course_group_fixture(scope)
      assert %Ecto.Changeset{} = Courses.change_course_group(scope, course_group)
    end
  end

  describe "tasks" do
    alias Studtasks.Courses.Task

    import Studtasks.AccountsFixtures, only: [user_scope_fixture: 0]
    import Studtasks.CoursesFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_tasks/1 returns all scoped tasks" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(other_scope)
      assert Courses.list_tasks(scope) == [task]
      assert Courses.list_tasks(other_scope) == [other_task]
    end

    test "get_task!/2 returns the task with given id" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_scope = user_scope_fixture()
      assert Courses.get_task!(scope, task.id) == task
      assert_raise Ecto.NoResultsError, fn -> Courses.get_task!(other_scope, task.id) end
    end

    test "create_task/2 with valid data creates a task" do
      valid_attrs = %{name: "some name", description: "some description"}
      scope = user_scope_fixture()
      course_group = course_group_fixture(scope)

      assert {:ok, %Task{} = task} =
               Courses.create_task(scope, Map.put(valid_attrs, :course_group_id, course_group.id))

      assert task.name == "some name"
      assert task.description == "some description"
      assert task.user_id == scope.user.id
    end

    test "create_task/2 with parent_id creates a child task" do
      scope = user_scope_fixture()
      parent = task_fixture(scope, %{name: "parent"})

      child_attrs = %{
        name: "child",
        description: "child desc",
        course_group_id: parent.course_group_id,
        parent_id: parent.id
      }

      assert {:ok, %Task{} = child} = Courses.create_task(scope, child_attrs)
      assert child.parent_id == parent.id
      # Reload parent to ensure child appears
      reloaded_parent = Courses.get_task!(scope, parent.id) |> Studtasks.Repo.preload(:children)
      assert Enum.any?(reloaded_parent.children, &(&1.id == child.id))
    end

    test "update_task/3 can set a parent" do
      scope = user_scope_fixture()
      parent = task_fixture(scope, %{name: "parent"})
      # ensure child belongs to the same course group as parent
      child = task_fixture(scope, %{name: "child", course_group_id: parent.course_group_id})

      assert {:ok, %Task{} = updated_child} =
               Courses.update_task(scope, child, %{parent_id: parent.id})

      assert updated_child.parent_id == parent.id
    end

    test "parent must belong to same course group" do
      scope = user_scope_fixture()
      parent = task_fixture(scope, %{name: "parent"})
      other_group_task_scope = user_scope_fixture()
      other_task = task_fixture(other_group_task_scope, %{name: "other"})

      # attempt to set parent from different group should error
      assert {:error, changeset} = Courses.update_task(scope, parent, %{parent_id: other_task.id})
      assert "parent must belong to the same course group" in errors_on(changeset).parent_id
    end

    test "cannot set parent that itself has a parent (only one level depth)" do
      scope = user_scope_fixture()
      grandparent = task_fixture(scope, %{name: "grandparent"})

      # create a parent whose parent is the grandparent (same group)
      {:ok, parent} =
        Courses.create_task(scope, %{
          name: "parent",
          course_group_id: grandparent.course_group_id,
          parent_id: grandparent.id
        })

      # now attempt to create a child whose parent already has a parent
      assert {:error, changeset} =
               Courses.create_task(scope, %{
                 name: "child",
                 course_group_id: grandparent.course_group_id,
                 parent_id: parent.id
               })

      assert "parent task already has a parent; only one level allowed" in errors_on(changeset).parent_id
    end

    test "create_task/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Courses.create_task(scope, @invalid_attrs)
    end

    test "update_task/3 with valid data updates the task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Task{} = task} = Courses.update_task(scope, task, update_attrs)
      assert task.name == "some updated name"
      assert task.description == "some updated description"
    end

    test "update_task/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)

      assert_raise MatchError, fn ->
        Courses.update_task(other_scope, task, %{})
      end
    end

    test "update_task/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Courses.update_task(scope, task, @invalid_attrs)
      assert task == Courses.get_task!(scope, task.id)
    end

    test "delete_task/2 deletes the task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      assert {:ok, %Task{}} = Courses.delete_task(scope, task)
      assert_raise Ecto.NoResultsError, fn -> Courses.get_task!(scope, task.id) end
    end

    test "delete_task/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      assert_raise MatchError, fn -> Courses.delete_task(other_scope, task) end
    end

    test "change_task/2 returns a task changeset" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      assert %Ecto.Changeset{} = Courses.change_task(scope, task)
    end
  end
end
