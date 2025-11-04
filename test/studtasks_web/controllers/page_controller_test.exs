defmodule StudtasksWeb.PageControllerTest do
  use StudtasksWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)
    assert body =~ "nadhem"
    assert body =~ "Organize your course projects and assignments"
  end
end
