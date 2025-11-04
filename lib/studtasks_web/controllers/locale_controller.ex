defmodule StudtasksWeb.LocaleController do
  use StudtasksWeb, :controller

  @locales ~w(en ar)

  def update(conn, %{"locale" => locale}) do
    locale = if locale in @locales, do: locale, else: "en"
    conn
    |> put_session(:locale, locale)
    |> redirect(to: get_referer(conn) || ~p"/")
  end

  defp get_referer(conn) do
    conn |> Plug.Conn.get_req_header("referer") |> List.first()
  end
end
