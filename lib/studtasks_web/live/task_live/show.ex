defmodule StudtasksWeb.TaskLive.Show do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@task.name}
        <:subtitle>Task details for {@course_group.name || @course_group.id}</:subtitle>
        <:actions>
          <.button navigate={~p"/groups/#{@course_group}/tasks"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/groups/#{@course_group}/tasks/#{@task}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit task
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Description">{@task.description}</:item>
        <:item title="Assigned to">
          {if @task.assignee, do: @task.assignee.name || @task.assignee.email, else: "Unassigned"}
        </:item>
        <:item title="Status">{format_status(@task.status)}</:item>
        <:item title="Priority">{String.capitalize(@task.priority || "")}</:item>
        <:item title="Due date">
          {@task.due_date && Calendar.strftime(@task.due_date, "%b %-d, %Y")}
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id, "group_id" => group_id}, _session, socket) do
    if connected?(socket) do
      Courses.subscribe_tasks(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Task")
     |> assign(:course_group, Courses.get_course_group!(socket.assigns.current_scope, group_id))
     |> assign(:task, Courses.get_task_in_group!(socket.assigns.current_scope, id, group_id))}
  end

  @impl true
  def handle_info(
        {:updated, %Studtasks.Courses.Task{id: id} = task},
        %{assigns: %{task: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :task, task)}
  end

  def handle_info(
        {:deleted, %Studtasks.Courses.Task{id: id}},
        %{assigns: %{task: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current task was deleted.")
     |> push_navigate(to: ~p"/groups/#{socket.assigns.course_group}/tasks")}
  end

  def handle_info({type, %Studtasks.Courses.Task{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  defp format_status("in_progress"), do: "In Progress"
  defp format_status("todo"), do: "Todo"
  defp format_status("backlog"), do: "Backlog"
  defp format_status("done"), do: "Done"
  defp format_status(other) when is_binary(other), do: String.capitalize(other)
end
