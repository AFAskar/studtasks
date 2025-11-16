defmodule StudtasksWeb.LocaleController do
  use StudtasksWeb, :controller

  @locales ~w(en ar)

  def update(conn, %{"locale" => locale}) do
    locale = if locale in @locales, do: locale, else: "en"

    conn
    |> put_session(:locale, locale)
    |> redirect(to: get_referer_path(conn) || ~p"/")
  end

  defp get_referer_path(conn) do
    case Plug.Conn.get_req_header(conn, "referer") do
      [referer | _] ->
        # Extract just the path from the full URL
        uri = URI.parse(referer)
        path = uri.path || "/"

        # Include query string if present
        if uri.query do
          "#{path}?#{uri.query}"
        else
          path
        end

      [] ->
        nil
    end
  end
end
