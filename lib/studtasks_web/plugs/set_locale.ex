defmodule StudtasksWeb.Plugs.SetLocale do
  @moduledoc """
  Sets the Gettext locale from the session (defaults to "en").
  """
  import Plug.Conn

  @locales ~w(en ar)

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = get_session(conn, :locale) || "en"
    locale = if locale in @locales, do: locale, else: "en"
    Gettext.put_locale(StudtasksWeb.Gettext, locale)
    assign(conn, :locale, locale)
  end
end
