defmodule Studtasks.CoursesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Studtasks.Courses` context.
  """

  @doc """
  Generate a course_group.
  """
  def course_group_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        name: "some name"
      })

    {:ok, course_group} = Studtasks.Courses.create_course_group(scope, attrs)
    course_group
  end

  @doc """
  Generate a task.
  """
  def task_fixture(scope, attrs \\ %{}) do
    # Ensure a course group exists and set the foreign key
    course_group = course_group_fixture(scope)

    attrs =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        course_group_id: course_group.id
      })

    {:ok, task} = Studtasks.Courses.create_task(scope, attrs)
    task
  end
end
