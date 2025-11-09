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

      assert {:ok, form_live, _html} =
               index_live
               |> element("#tasks-#{task.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/groups/#{task.course_group_id}/tasks/#{task}/edit")

      assert render(form_live) =~ "Edit Task"

      assert form_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#task-form", task: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/groups/#{task.course_group_id}/tasks")

      html = render(index_live)
      assert html =~ "Task updated successfully"
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

    test "updates task and returns to show", %{conn: conn, task: task} do
      {:ok, show_live, _html} = live(conn, ~p"/groups/#{task.course_group_id}/tasks/#{task}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(
                 conn,
                 ~p"/groups/#{task.course_group_id}/tasks/#{task}/edit?return_to=show"
               )

      assert render(form_live) =~ "Edit Task"

      assert form_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#task-form", task: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/groups/#{task.course_group_id}/tasks/#{task}")

      html = render(show_live)
      assert html =~ "Task updated successfully"
      assert html =~ "some updated name"
    end
  end
end
