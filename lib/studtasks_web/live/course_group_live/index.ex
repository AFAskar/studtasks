defmodule StudtasksWeb.CourseGroupLive.Index do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Course groups
        <:actions>
          <.button variant="primary" navigate={~p"/course_groups/new"}>
            <.icon name="hero-plus" /> New Course group
          </.button>
        </:actions>
      </.header>

      <.table
        id="course_groups"
        rows={@streams.course_groups}
        row_click={fn {_id, course_group} -> JS.navigate(~p"/course_groups/#{course_group}") end}
      >
        <:col :let={{_id, course_group}} label="Name">{course_group.name}</:col>
        <:col :let={{_id, course_group}} label="Description">{course_group.description}</:col>
        <:action :let={{_id, course_group}}>
          <div class="sr-only">
            <.link navigate={~p"/course_groups/#{course_group}"}>Show</.link>
          </div>
          <.link navigate={~p"/course_groups/#{course_group}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, course_group}}>
          <.link
            phx-click={JS.push("delete", value: %{id: course_group.id}) |> hide("##" <> id)}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Courses.subscribe_course_groups(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Course groups")
     |> stream(:course_groups, list_course_groups(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    course_group = Courses.get_course_group!(socket.assigns.current_scope, id)
    {:ok, _} = Courses.delete_course_group(socket.assigns.current_scope, course_group)

    {:noreply, stream_delete(socket, :course_groups, course_group)}
  end

  @impl true
  def handle_info({type, %Studtasks.Courses.CourseGroup{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :course_groups, list_course_groups(socket.assigns.current_scope), reset: true)}
  end

  defp list_course_groups(current_scope) do
    Courses.list_course_groups(current_scope)
  end
end
