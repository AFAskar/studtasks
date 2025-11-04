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
      assert_raise Ecto.NoResultsError, fn -> Courses.get_course_group!(other_scope, course_group.id) end
    end

    test "create_course_group/2 with valid data creates a course_group" do
      valid_attrs = %{name: "some name", description: "some description"}
      scope = user_scope_fixture()

      assert {:ok, %CourseGroup{} = course_group} = Courses.create_course_group(scope, valid_attrs)
      assert course_group.name == "some name"
      assert course_group.description == "some description"
      assert course_group.user_id == scope.user.id
    end

    test "create_course_group/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Courses.create_course_group(scope, @invalid_attrs)
    end

    test "update_course_group/3 with valid data updates the course_group" do
      scope = user_scope_fixture()
      course_group = course_group_fixture(scope)
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %CourseGroup{} = course_group} = Courses.update_course_group(scope, course_group, update_attrs)
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
      assert {:error, %Ecto.Changeset{}} = Courses.update_course_group(scope, course_group, @invalid_attrs)
      assert course_group == Courses.get_course_group!(scope, course_group.id)
    end

    test "delete_course_group/2 deletes the course_group" do
      scope = user_scope_fixture()
      course_group = course_group_fixture(scope)
      assert {:ok, %CourseGroup{}} = Courses.delete_course_group(scope, course_group)
      assert_raise Ecto.NoResultsError, fn -> Courses.get_course_group!(scope, course_group.id) end
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

      assert {:ok, %Task{} = task} = Courses.create_task(scope, valid_attrs)
      assert task.name == "some name"
      assert task.description == "some description"
      assert task.user_id == scope.user.id
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
