defmodule StudtasksWeb.CourseGroupLiveTest do
  use StudtasksWeb.ConnCase

  import Phoenix.LiveViewTest
  import Studtasks.CoursesFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  setup :register_and_log_in_user

  defp create_course_group(%{scope: scope}) do
    course_group = course_group_fixture(scope)

    %{course_group: course_group}
  end

  describe "Index" do
    setup [:create_course_group]

    test "lists all course_groups", %{conn: conn, course_group: course_group} do
      {:ok, _index_live, html} = live(conn, ~p"/groups")

      assert html =~ "Listing Course groups"
      assert html =~ course_group.name
    end

    test "saves new course_group", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/groups")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Course group")
               |> render_click()
               |> follow_redirect(conn, ~p"/groups/new")

      assert render(form_live) =~ "New Course group"

      assert form_live
             |> form("#course_group-form", course_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#course_group-form", course_group: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/groups")

      html = render(index_live)
      assert html =~ "Course group created successfully"
      assert html =~ "some name"
    end

    test "updates course_group in listing", %{conn: conn, course_group: course_group} do
      {:ok, index_live, _html} = live(conn, ~p"/groups")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#course_groups-#{course_group.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/groups/#{course_group}/edit")

      assert render(form_live) =~ "Edit Course group"

      assert form_live
             |> form("#course_group-form", course_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#course_group-form", course_group: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/groups")

      html = render(index_live)
      assert html =~ "Course group updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes course_group in listing", %{conn: conn, course_group: course_group} do
      {:ok, index_live, _html} = live(conn, ~p"/groups")

      assert index_live
             |> element("#course_groups-#{course_group.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#course_groups-#{course_group.id}")
    end
  end

  describe "Show" do
    setup [:create_course_group]

    test "displays course_group", %{conn: conn, course_group: course_group} do
      {:ok, _show_live, html} = live(conn, ~p"/groups/#{course_group}")

      assert html =~ "Show Course group"
      assert html =~ course_group.name
    end

    test "updates course_group and returns to show", %{conn: conn, course_group: course_group} do
      {:ok, show_live, _html} = live(conn, ~p"/groups/#{course_group}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/groups/#{course_group}/edit?return_to=show")

      assert render(form_live) =~ "Edit Course group"

      assert form_live
             |> form("#course_group-form", course_group: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#course_group-form", course_group: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/groups/#{course_group}")

      html = render(show_live)
      assert html =~ "Course group updated successfully"
      assert html =~ "some updated name"
    end
  end
end
