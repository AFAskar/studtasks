defmodule StudtasksWeb.TaskLive.Index do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {if @view_mode == :list, do: "Listing Tasks", else: "Tasks"}
        <:subtitle>Plan and track work for {@course_group.name || @course_group.id}</:subtitle>
        <:actions>
          <div class="join hidden sm:inline-flex">
            <.link
              patch={~p"/groups/#{@course_group}/tasks?view=list"}
              class={["btn join-item", @view_mode == :list && "btn-active"]}
            >
              <.icon name="hero-list-bullet" />
              <span class="ml-1 hidden md:inline">List</span>
            </.link>
            <.link
              patch={~p"/groups/#{@course_group}/tasks?view=board"}
              class={["btn join-item", @view_mode == :board && "btn-active"]}
            >
              <.icon name="hero-rectangle-group" />
              <span class="ml-1 hidden md:inline">Board</span>
            </.link>
          </div>
          <.button variant="primary" navigate={~p"/groups/#{@course_group}/tasks/new"}>
            <.icon name="hero-plus" /> New Task
          </.button>
        </:actions>
      </.header>

      <%= if @view_mode == :list do %>
        <.table
          id="tasks"
          rows={@streams.tasks}
          row_click={fn {_id, task} -> JS.navigate(~p"/groups/#{@course_group}/tasks/#{task}") end}
        >
          <:col :let={{_id, task}} label="Name">{task.name}</:col>
          <:col :let={{_id, task}} label="Description">{task.description}</:col>
          <:col :let={{_id, task}} label="Assignee">
            {task.assignee && (task.assignee.name || task.assignee.email)}
          </:col>
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
      <% else %>
        <div
          id="kanban"
          phx-hook=".Kanban"
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4"
        >
          <%= for {assignee_key, column} <- @board_columns do %>
            <div class="card bg-base-200/60 border border-base-300">
              <div class="flex items-center justify-between px-3 py-2 border-b">
                <div class="flex items-center gap-2">
                  <div class="avatar placeholder">
                    <div class="w-6 rounded-full bg-neutral text-neutral-content">
                      <span class="text-xs">
                        {case column.assignee do
                          nil -> "?"
                          a -> (a.name || a.email || "?") |> String.slice(0, 1) |> String.upcase()
                        end}
                      </span>
                    </div>
                  </div>
                  <h3 class="text-sm font-semibold">
                    {if column.assignee,
                      do: column.assignee.name || column.assignee.email,
                      else: "Unassigned"}
                  </h3>
                  <span class="badge badge-ghost">{length(column.tasks)}</span>
                </div>
                <.link navigate={~p"/groups/#{@course_group}/tasks/new"} class="btn btn-xs">
                  <.icon name="hero-plus" />
                </.link>
              </div>
              <div
                class="p-2 min-h-64 space-y-2"
                data-assignee={assignee_key}
                data-drop-zone="true"
              >
                <%= if column.tasks == [] do %>
                  <div class="text-sm opacity-60 px-2 py-8 text-center">Drop here to assign</div>
                <% end %>
                <%= for task <- column.tasks do %>
                  <div
                    id={"task-" <> task.id}
                    class="card bg-base-100 border border-base-300 hover:border-primary/50 transition-colors"
                    draggable="true"
                    data-task-id={task.id}
                  >
                    <div class="card-body p-3 gap-2">
                      <div class="flex items-start justify-between gap-2">
                        <h4 class="font-medium leading-5 truncate">{task.name}</h4>
                        <div class="dropdown dropdown-end">
                          <div tabindex="0" role="button" class="btn btn-ghost btn-xs">
                            <.icon name="hero-ellipsis-vertical" />
                          </div>
                          <ul
                            tabindex="0"
                            class="dropdown-content menu bg-base-100 rounded-box z-50 w-40 p-2 shadow"
                          >
                            <li>
                              <.link navigate={~p"/groups/#{@course_group}/tasks/#{task}"}>
                                Open
                              </.link>
                            </li>
                            <li>
                              <.link navigate={~p"/groups/#{@course_group}/tasks/#{task}/edit"}>
                                Edit
                              </.link>
                            </li>
                            <li>
                              <button phx-click={JS.push("delete", value: %{id: task.id})}>
                                Delete
                              </button>
                            </li>
                          </ul>
                        </div>
                      </div>
                      <p class="text-sm opacity-70 line-clamp-3">{task.description}</p>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center gap-2">
                          <div class="avatar placeholder">
                            <div class="w-6 rounded-full bg-neutral text-neutral-content">
                              <span class="text-xs">
                                {if task.assignee,
                                  do:
                                    (task.assignee.name || task.assignee.email)
                                    |> String.slice(0, 1)
                                    |> String.upcase(),
                                  else: "?"}
                              </span>
                            </div>
                          </div>
                          <span class="text-xs opacity-70 truncate max-w-36">
                            {if task.assignee,
                              do: task.assignee.name || task.assignee.email,
                              else: "Unassigned"}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>

        <script :type={Phoenix.LiveView.ColocatedHook} name=".Kanban">
          export default {
            mounted(){
              this.dragged = null
              this.el.addEventListener("dragstart", (e) => {
                const card = e.target.closest('[data-task-id]')
                if(!card) return
                this.dragged = card
                e.dataTransfer?.setData("text/plain", card.dataset.taskId)
                e.dataTransfer?.setDragImage(card, 10, 10)
              })
              this.el.addEventListener("dragend", () => { this.dragged = null })
              this.el.addEventListener("dragover", (e) => {
                if(e.target.closest('[data-drop-zone]')){ e.preventDefault() }
              })
              this.el.addEventListener("drop", (e) => {
                const zone = e.target.closest('[data-drop-zone]')
                if(!zone) return
                e.preventDefault()
                const taskId = this.dragged?.dataset.taskId || e.dataTransfer?.getData("text/plain")
                const assignee = zone.dataset.assignee || null
                if(taskId){ this.pushEvent("kanban:move", {task_id: taskId, assignee_id: assignee}) }
              })
            }
          }
        </script>
      <% end %>
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
     |> assign(:view_mode, :list)
     |> assign_board(list_tasks(socket.assigns.current_scope, group_id))
     |> stream(:tasks, list_tasks(socket.assigns.current_scope, group_id))}
  end

  @impl true
  def handle_params(%{"view" => "list"}, _uri, socket) do
    {:noreply, assign(socket, :view_mode, :list)}
  end

  def handle_params(%{"view" => "board"}, _uri, socket) do
    {:noreply, assign(socket, :view_mode, :board)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Courses.get_task!(socket.assigns.current_scope, id)
    {:ok, _} = Courses.delete_task(socket.assigns.current_scope, task)

    {:noreply, stream_delete(socket, :tasks, task)}
  end

  def handle_event("kanban:move", %{"task_id" => id, "assignee_id" => assignee_id}, socket) do
    task = Courses.get_task!(socket.assigns.current_scope, id)
    params = %{assignee_id: assignee_id}
    {:ok, _task} = Courses.update_task(socket.assigns.current_scope, task, params)

    tasks = list_tasks(socket.assigns.current_scope, socket.assigns.course_group.id)
    {:noreply, assign_board(socket, tasks)}
  end

  @impl true
  def handle_info({type, %Studtasks.Courses.Task{}}, socket)
      when type in [:created, :updated, :deleted] do
    tasks = list_tasks(socket.assigns.current_scope, socket.assigns.course_group.id)

    {:noreply,
     socket
     |> assign_board(tasks)
     |> stream(:tasks, tasks, reset: true)}
  end

  defp list_tasks(current_scope, group_id) do
    Courses.list_group_tasks(current_scope, group_id)
  end

  defp assign_board(socket, tasks) do
    # Group tasks by assignee_id, include a nil bucket for Unassigned
    grouped = Enum.group_by(tasks, fn t -> t.assignee_id end)

    # Build columns as a keyword list preserving order: Unassigned first, then alphabetically by assignee name/email
    assignees =
      tasks
      |> Enum.map(& &1.assignee)
      |> Enum.uniq_by(&(&1 && &1.id))
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(fn a -> (a.name || a.email || "") |> String.downcase() end)

    columns = [
      {nil, %{assignee: nil, tasks: Map.get(grouped, nil, [])}}
      | Enum.map(assignees, fn a -> {a.id, %{assignee: a, tasks: Map.get(grouped, a.id, [])}} end)
    ]

    assign(socket, board_columns: columns)
  end
end
