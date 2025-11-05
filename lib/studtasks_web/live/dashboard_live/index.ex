defmodule StudtasksWeb.DashboardLive.Index do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Dashboard
        <:subtitle>Overview of your work and groups</:subtitle>
        <:actions>
          <div class="flex items-center gap-2">
            <span class="badge badge-ghost">Groups: {@group_count}</span>
            <span class="badge badge-ghost">Assigned: {@assigned_count}</span>
            <.button variant="primary" navigate={~p"/groups/new"}>
              <.icon name="hero-plus" /> New Group
            </.button>
          </div>
        </:actions>
      </.header>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="card bg-base-200/60 border border-base-300">
          <div class="card-body">
            <div class="flex items-center justify-between">
              <h3 class="card-title text-base">Assigned to me</h3>
              <.link navigate={~p"/dashboard/tasks?type=assigned"} class="link link-primary text-sm">
                View all
              </.link>
            </div>
            <div :if={@assigned_tasks == []} class="text-sm opacity-70">No assigned tasks.</div>
            <ul class="divide-y divide-base-300">
              <li :for={task <- @assigned_tasks} class="py-3 flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <div class="flex items-center gap-2">
                    <.link
                      navigate={~p"/groups/#{task.course_group}/tasks/#{task}"}
                      class="font-medium hover:underline truncate"
                    >
                      {task.name}
                    </.link>
                    <span class={[
                      "badge badge-xs",
                      priority_badge_class(task.priority)
                    ]}>
                      {String.capitalize(task.priority || "")}
                    </span>
                  </div>
                  <div class="text-xs opacity-70 truncate">
                    in {task.course_group && (task.course_group.name || task.course_group.id)}
                  </div>
                </div>
                <div class="flex items-center gap-2 text-xs opacity-70 shrink-0">
                  <span :if={task.due_date} class="badge badge-ghost badge-sm">
                    <.icon name="hero-calendar" class="size-3 mr-1" /> {Calendar.strftime(
                      task.due_date,
                      "%b %-d"
                    )}
                  </span>
                </div>
              </li>
            </ul>
          </div>
        </div>

        <div class="card bg-base-200/60 border border-base-300">
          <div class="card-body">
            <div class="flex items-center justify-between">
              <h3 class="card-title text-base">Recent tasks</h3>
              <.link navigate={~p"/dashboard/tasks?type=recent"} class="link link-primary text-sm">
                View all
              </.link>
            </div>
            <div :if={@recent_tasks == []} class="text-sm opacity-70">No recent tasks.</div>
            <ul class="divide-y divide-base-300">
              <li :for={task <- @recent_tasks} class="py-3 flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <div class="flex items-center gap-2">
                    <.link
                      navigate={~p"/groups/#{task.course_group}/tasks/#{task}"}
                      class="font-medium hover:underline truncate"
                    >
                      {task.name}
                    </.link>
                    <span class={[
                      "badge badge-xs",
                      priority_badge_class(task.priority)
                    ]}>
                      {String.capitalize(task.priority || "")}
                    </span>
                  </div>
                  <div class="text-xs opacity-70 truncate">
                    in {task.course_group && (task.course_group.name || task.course_group.id)} • {format_status(
                      task.status
                    )}
                  </div>
                </div>
                <div class="flex items-center gap-2 text-xs opacity-70 shrink-0">
                  <span :if={task.due_date} class="badge badge-ghost badge-sm">
                    <.icon name="hero-calendar" class="size-3 mr-1" /> {Calendar.strftime(
                      task.due_date,
                      "%b %-d"
                    )}
                  </span>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <div class="mt-8">
        <.header>
          Your groups
        </.header>

        <.table
          id="course_groups"
          rows={@streams.course_groups}
          row_click={fn {_id, course_group} -> JS.navigate(~p"/groups/#{course_group}") end}
        >
          <:col :let={{_id, course_group}} label="Name">{course_group.name}</:col>
          <:col :let={{_id, course_group}} label="Description">{course_group.description}</:col>
          <:action :let={{_id, course_group}}>
            <div class="sr-only">
              <.link navigate={~p"/groups/#{course_group}"}>Show</.link>
            </div>
            <.link navigate={~p"/groups/#{course_group}/edit"}>Edit</.link>
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
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Courses.subscribe_course_groups(socket.assigns.current_scope)
      Courses.subscribe_tasks(socket.assigns.current_scope)
    end

    assigned = Courses.list_assigned_tasks(socket.assigns.current_scope, 5)
    recent = Courses.list_recent_tasks(socket.assigns.current_scope, 5)
    groups = list_course_groups(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:assigned_tasks, assigned)
     |> assign(:recent_tasks, recent)
     |> assign(:group_count, length(groups))
     |> assign(
       :assigned_count,
       length(Courses.list_assigned_tasks_all(socket.assigns.current_scope))
     )
     |> stream(:course_groups, groups)}
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
    groups = list_course_groups(socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:group_count, length(groups))
     |> stream(:course_groups, groups, reset: true)}
  end

  @impl true
  def handle_info({type, %Studtasks.Courses.Task{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     socket
     |> assign(:assigned_tasks, Courses.list_assigned_tasks(socket.assigns.current_scope, 5))
     |> assign(:recent_tasks, Courses.list_recent_tasks(socket.assigns.current_scope, 5))
     |> assign(
       :assigned_count,
       length(Courses.list_assigned_tasks_all(socket.assigns.current_scope))
     )}
  end

  defp list_course_groups(current_scope) do
    Courses.list_course_groups(current_scope)
  end

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
