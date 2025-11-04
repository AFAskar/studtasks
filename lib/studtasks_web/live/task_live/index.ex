defmodule StudtasksWeb.TaskLive.Index do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Tasks
        <:actions>
          <.button variant="primary" navigate={~p"/groups/#{@course_group}/tasks/new"}>
            <.icon name="hero-plus" /> New Task
          </.button>
        </:actions>
      </.header>

      <.table
        id="tasks"
        rows={@streams.tasks}
        row_click={fn {_id, task} -> JS.navigate(~p"/groups/#{@course_group}/tasks/#{task}") end}
      >
        <:col :let={{_id, task}} label="Name">{task.name}</:col>
        <:col :let={{_id, task}} label="Description">{task.description}</:col>
        <:action :let={{_id, task}}>
          <div class="sr-only">
            <.link navigate={~p"/groups/#{@course_group}/tasks/#{task}"}>Show</.link>
          </div>
          <.link navigate={~p"/groups/#{@course_group}/tasks/#{task}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, task}}>
          <.link
            phx-click={JS.push("delete", value: %{id: task.id}) |> hide("##" <> id)}
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
  def mount(%{"group_id" => group_id}, _session, socket) do
    if connected?(socket) do
      Courses.subscribe_tasks(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Tasks")
     |> assign(:course_group, Courses.get_course_group!(socket.assigns.current_scope, group_id))
     |> stream(:tasks, list_tasks(socket.assigns.current_scope, group_id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Courses.get_task!(socket.assigns.current_scope, id)
    {:ok, _} = Courses.delete_task(socket.assigns.current_scope, task)

    {:noreply, stream_delete(socket, :tasks, task)}
  end

  @impl true
  def handle_info({type, %Studtasks.Courses.Task{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(
       socket,
       :tasks,
       list_tasks(socket.assigns.current_scope, socket.assigns.course_group.id),
       reset: true
     )}
  end

  defp list_tasks(current_scope, group_id) do
    Courses.list_group_tasks(current_scope, group_id)
  end
end
