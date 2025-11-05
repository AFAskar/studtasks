defmodule StudtasksWeb.DashboardTasksLive do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Tasks across your groups
        <:subtitle>
          {if @type == :assigned, do: "Assigned to you", else: "Most recent"}
        </:subtitle>
        <:actions>
          <div class="join">
            <.link
              patch={~p"/dashboard/tasks?type=assigned"}
              class={["btn join-item", @type == :assigned && "btn-active"]}
            >
              <.icon name="hero-user" />
              <span class="ml-1 hidden md:inline">Assigned</span>
            </.link>
            <.link
              patch={~p"/dashboard/tasks?type=recent"}
              class={["btn join-item", @type == :recent && "btn-active"]}
            >
              <.icon name="hero-clock" />
              <span class="ml-1 hidden md:inline">Recent</span>
            </.link>
          </div>
        </:actions>
      </.header>

      <.table
        id="dashboard_tasks"
        rows={@streams.tasks}
        row_click={fn {_id, task} -> JS.navigate(~p"/groups/#{task.course_group}/tasks/#{task}") end}
      >
        <:col :let={{_id, task}} label="Name">{task.name}</:col>
        <:col :let={{_id, task}} label="Group">
          {task.course_group && (task.course_group.name || task.course_group.id)}
        </:col>
        <:col :let={{_id, task}} label="Priority">
          <span class={["badge badge-xs", priority_badge_class(task.priority)]}>
            {String.capitalize(task.priority || "")}
          </span>
        </:col>
        <:col :let={{_id, task}} label="Status">{format_status(task.status)}</:col>
        <:col :let={{_id, task}} label="Due">
          {task.due_date && Calendar.strftime(task.due_date, "%b %-d")}
        </:col>
        <:col :let={{_id, task}} label="Assigned to">
          {task.assignee && (task.assignee.name || task.assignee.email)}
        </:col>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket) do
      Courses.subscribe_tasks(socket.assigns.current_scope)
    end

    type = type_from_params(params)
    tasks = fetch_tasks(socket.assigns.current_scope, type)

    {:ok,
     socket
     |> assign(:type, type)
     |> stream(:tasks, tasks)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    type = type_from_params(params)
    tasks = fetch_tasks(socket.assigns.current_scope, type)

    {:noreply,
     socket
     |> assign(:type, type)
     |> stream(:tasks, tasks, reset: true)}
  end

  @impl true
  def handle_info({type, %Studtasks.Courses.Task{}}, socket)
      when type in [:created, :updated, :deleted] do
    tasks = fetch_tasks(socket.assigns.current_scope, socket.assigns.type)
    {:noreply, stream(socket, :tasks, tasks, reset: true)}
  end

  defp type_from_params(%{"type" => "recent"}), do: :recent
  defp type_from_params(_), do: :assigned

  defp fetch_tasks(scope, :assigned), do: Courses.list_assigned_tasks_all(scope)
  defp fetch_tasks(scope, :recent), do: Courses.list_recent_tasks_all(scope)

  defp priority_badge_class("urgent"), do: "badge-error"
  defp priority_badge_class("high"), do: "badge-warning"
  defp priority_badge_class("medium"), do: "badge-info"
  defp priority_badge_class("low"), do: "badge-ghost"
  defp priority_badge_class(_), do: "badge-ghost"

  defp format_status("in_progress"), do: "In Progress"
  defp format_status("todo"), do: "Todo"
  defp format_status("backlog"), do: "Backlog"
  defp format_status("done"), do: "Done"
  defp format_status(other) when is_binary(other), do: String.capitalize(other)
end
