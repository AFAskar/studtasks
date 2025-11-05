defmodule StudtasksWeb.CourseGroupLive.Show do
  use StudtasksWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Groups page deprecated
        <:subtitle>Please use the Dashboard instead.</:subtitle>
        <:actions>
          <.link navigate={~p"/dashboard"} class="btn btn-primary">Go to Dashboard</.link>
        </:actions>
      </.header>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Group (deprecated)")}
  end
end
