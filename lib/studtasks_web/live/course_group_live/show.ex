defmodule StudtasksWeb.CourseGroupLive.Show do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Course group {@course_group.id}
        <:subtitle>This is a course_group record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/course_groups"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button navigate={~p"/groups/#{@course_group}/tasks"}>
            <.icon name="hero-list-bullet" /> View tasks
          </.button>
          <.button variant="primary" navigate={~p"/course_groups/#{@course_group}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit course_group
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@course_group.name}</:item>
        <:item title="Description">{@course_group.description}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Courses.subscribe_course_groups(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Course group")
     |> assign(:course_group, Courses.get_course_group!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Studtasks.Courses.CourseGroup{id: id} = course_group},
        %{assigns: %{course_group: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :course_group, course_group)}
  end

  def handle_info(
        {:deleted, %Studtasks.Courses.CourseGroup{id: id}},
        %{assigns: %{course_group: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current course_group was deleted.")
     |> push_navigate(to: ~p"/course_groups")}
  end

  def handle_info({type, %Studtasks.Courses.CourseGroup{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
