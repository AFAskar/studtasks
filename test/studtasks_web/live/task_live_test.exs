defmodule StudtasksWeb.TaskLiveTest do
  use StudtasksWeb.ConnCase

  import Phoenix.LiveViewTest
  import Studtasks.CoursesFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  setup :register_and_log_in_user

  defp create_task(%{scope: scope}) do
    task = task_fixture(scope)

    %{task: task}
  end

  describe "Index" do
    setup [:create_task]

    test "lists all tasks", %{conn: conn, task: task} do
      {:ok, _index_live, html} = live(conn, ~p"/groups/#{task.course_group_id}/tasks")

      assert html =~ "Listing Tasks"
      assert html =~ task.name
    end

    test "shows group stats visualization", %{conn: conn, task: task} do
      {:ok, index_live, _html} = live(conn, ~p"/groups/#{task.course_group_id}/tasks")

      assert has_element?(index_live, "#group-stats")
    end

    test "saves new task via quick modal", %{conn: conn, task: task} do
      {:ok, index_live, _html} = live(conn, ~p"/groups/#{task.course_group_id}/tasks")

      _ = index_live |> element("button", "New Task") |> render_click()

      # submit invalid (missing name) - expect validation error from changeset
      assert index_live
             |> form("#quick-form", task: @invalid_attrs)
             |> render_submit() =~ "can&#39;t be blank"

      # submit valid
      _ =
        index_live
        |> form("#quick-form", task: @create_attrs)
        |> render_submit()

      html = render(index_live)
      assert html =~ "some name"
    end

    test "updates task in listing", %{conn: conn, task: task} do
      {:ok, index_live, _html} = live(conn, ~p"/groups/#{task.course_group_id}/tasks")

      _ =
        index_live
        |> element("#tasks-#{task.id} a", "Edit")
        |> render_click()

      # Modal should be visible
      assert has_element?(index_live, "#edit-modal")
      assert render(index_live) =~ "Edit task"

      # invalid submit
      assert index_live
             |> form("#edit-form", task: @invalid_attrs)
             |> render_submit() =~ "can&#39;t be blank"

      # valid submit
      _ = index_live |> form("#edit-form", task: @update_attrs) |> render_submit()

      html = render(index_live)
      assert html =~ "some updated name"
    end

    test "deletes task in listing", %{conn: conn, task: task} do
      {:ok, index_live, _html} = live(conn, ~p"/groups/#{task.course_group_id}/tasks")

      assert index_live |> element("#tasks-#{task.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#tasks-#{task.id}")
    end
  end

  describe "Show" do
    setup [:create_task]

    test "displays task", %{conn: conn, task: task} do
      {:ok, _show_live, html} = live(conn, ~p"/groups/#{task.course_group_id}/tasks/#{task}")

      assert html =~ "Show Task"
      assert html =~ task.name
    end

    test "updates task and stays on show", %{conn: conn, task: task} do
      {:ok, show_live, _html} = live(conn, ~p"/groups/#{task.course_group_id}/tasks/#{task}")

      _ = show_live |> element("button", "Edit task") |> render_click()

      assert has_element?(show_live, "#edit-modal")

      assert show_live
             |> form("#edit-form", task: @invalid_attrs)
             |> render_submit() =~ "can&#39;t be blank"

      _ = show_live |> form("#edit-form", task: @update_attrs) |> render_submit()

      html = render(show_live)
      assert html =~ "some updated name"
    end
  end
end
