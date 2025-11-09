defmodule StudtasksWeb.TaskLive.Index do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses
  alias Studtasks.Accounts
  alias Phoenix.LiveView.JS

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {if @view_mode == :list, do: "Listing Tasks", else: "Tasks"}
        <:subtitle>Plan and track work for {@course_group.name || @course_group.id}</:subtitle>
        <:actions>
          <div class="hidden lg:flex items-center gap-2 mr-2">
            <.form
              for={@filter_form}
              id="task-filters"
              phx-change="filters"
              class="flex items-center gap-2"
            >
              <.input
                type="select"
                field={@filter_form[:assignee_id]}
                prompt="Anyone"
                options={@assignee_options}
              />
              <label class="label cursor-pointer gap-1 text-xs">
                <.input type="checkbox" field={@filter_form[:unassigned]} /> Unassigned only
              </label>
              <.input type="search" field={@filter_form[:q]} placeholder="Search" />
              <.input type="select" field={@filter_form[:sort]} options={@sort_options} />
            </.form>
          </div>
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
          <.button
            variant="primary"
            phx-click={JS.push("open_quick_new", value: %{status: "backlog"})}
          >
            <.icon name="hero-plus" /> New Task
          </.button>
        </:actions>
      </.header>

      <div id="group-stats" class="grid grid-cols-1 gap-4 mb-4 md:grid-cols-3">
        <div class="card bg-base-200/60 border border-base-300">
          <div class="card-body flex flex-row items-center gap-4">
            <div
              class="radial-progress text-primary"
              style={"--value: #{@task_stats.percent_done}; --size: 4.5rem; --thickness: 6px"}
              role="progressbar"
              aria-valuemin="0"
              aria-valuemax="100"
              aria-valuenow={@task_stats.percent_done}
            >
              {@task_stats.percent_done}%
            </div>
            <div>
              <div class="text-sm opacity-70">Completed tasks</div>
              <div class="text-xl font-semibold">{@task_stats.done} / {@task_stats.total}</div>
            </div>
          </div>
        </div>

        <div class="card bg-base-200/60 border border-base-300 md:col-span-2">
          <div class="card-body">
            <div class="flex items-center justify-between">
              <div class="text-sm font-medium">By status</div>
              <div class="text-xs opacity-70">Total: {@task_stats.total}</div>
            </div>
            <div class="mt-3 space-y-3">
              <%= for {label, key, color} <- [{"Backlog", :backlog, "bg-neutral/100"},
                                              {"Todo", :todo, "bg-info/70"},
                                              {"In Progress", :in_progress, "bg-warning/70"},
                                              {"Done", :done, "bg-success/80"}] do %>
                <div class="flex items-center gap-3">
                  <div class="w-28 shrink-0 text-xs opacity-75">{label}</div>
                  <div class="grow">
                    <div class="h-2 rounded bg-base-300/60 overflow-hidden">
                      <div
                        class={[
                          "h-2",
                          "rounded",
                          color
                        ]}
                        style={"width: #{bar_width(@task_stats[key], @task_stats.total)}%"}
                      />
                    </div>
                  </div>
                  <div class="w-10 text-right text-xs tabular-nums">{@task_stats[key]}</div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <%= if @view_mode == :list do %>
        <.table
          id="tasks"
          rows={@streams.tasks}
          row_click={fn {_id, task} -> JS.navigate(~p"/groups/#{@course_group}/tasks/#{task}") end}
        >
          <:col :let={{_id, task}} label="Name">{task.name}</:col>
          <:col :let={{_id, task}} label="Description">{task.description}</:col>
          <:col :let={{_id, task}} label="Priority">{String.capitalize(task.priority || "")}</:col>
          <:col :let={{_id, task}} label="Status">{format_status(task.status)}</:col>
          <:col :let={{_id, task}} label="Due">
            {task.due_date && Calendar.strftime(task.due_date, "%b %-d")}
          </:col>
          <:col :let={{_id, task}} label="Parent">
            {task.parent && (task.parent.name || task.parent.id)}
          </:col>
          <:col :let={{_id, task}} label="Subtasks">{length(task.children)}</:col>
          <:col :let={{_id, task}} label="Assigned to">
            {task.assignee && (task.assignee.name || task.assignee.email)}
          </:col>
          <:action :let={{_id, task}}>
            <div class="sr-only">
              <.link navigate={~p"/groups/#{@course_group}/tasks/#{task}"}>Show</.link>
            </div>
            <.link phx-click={JS.push("open_edit", value: %{id: task.id})}>Edit</.link>
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
          <%= for {status, column} <- @board_columns do %>
            <div class="card h-full flex flex-col bg-base-200/60 border border-base-300">
              <div class="flex items-center justify-between px-3 py-2 border-b">
                <div class="flex items-center gap-2">
                  <h3 class="text-sm font-semibold">{format_status(status)}</h3>
                  <span class="badge badge-ghost">{length(column.tasks)}</span>
                </div>
                <button
                  class="btn btn-xs"
                  phx-click={JS.push("open_quick_new", value: %{status: status})}
                >
                  <.icon name="hero-plus" />
                </button>
              </div>
              <div class="p-2 min-h-64 space-y-2 flex-1" data-status={status} data-drop-zone="true">
                <%= if column.tasks == [] do %>
                  <div class="text-sm opacity-60 px-2 py-8 text-center">Drop here</div>
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
                        <h4 class="font-medium leading-5 line-clamp-2 flex-1">{task.name}</h4>
                        <div class="flex items-center gap-1">
                          <span class={["badge badge-xs", priority_badge_class(task.priority)]}>
                            {String.capitalize(task.priority || "")}
                          </span>
                          <span
                            :if={task.parent}
                            class="badge badge-xs badge-outline"
                            title="Parent task"
                          >
                            <.icon name="hero-arrow-up" class="size-3 mr-0.5" /> {task.parent.name ||
                              task.parent.id}
                          </span>
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
                                <button phx-click={JS.push("open_edit", value: %{id: task.id})}>
                                  Edit
                                </button>
                              </li>
                              <li>
                                <button phx-click={
                                  JS.push("open_quick_new",
                                    value: %{status: status, parent_id: task.id}
                                  )
                                }>
                                  Add subtask
                                </button>
                              </li>
                              <li>
                                <button phx-click={JS.push("delete", value: %{id: task.id})}>
                                  Delete
                                </button>
                              </li>
                            </ul>
                          </div>
                        </div>
                      </div>
                      <div class="flex flex-wrap items-center gap-1 mb-1">
                        <span class={["badge badge-sm", priority_badge_class(task.priority)]}>
                          {String.capitalize(task.priority || "")}
                        </span>
                        <span
                          :if={task.parent}
                          class="badge badge-sm badge-outline"
                          title="Parent task"
                        >
                          <.icon name="hero-arrow-up" class="size-3 mr-0.5" /> Parent
                        </span>
                      </div>
                      <p class="text-sm opacity-70 line-clamp-3">{task.description}</p>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center gap-2">
                          <span class="text-xs opacity-70 truncate max-w-36">
                            Assigned to: {if task.assignee,
                              do: task.assignee.name || task.assignee.email,
                              else: "Unassigned"}
                          </span>
                        </div>
                        <div class="flex items-center gap-2">
                          <span :if={task.due_date} class="badge badge-ghost badge-sm">
                            <.icon name="hero-calendar" class="size-3 mr-1" />
                            {Calendar.strftime(task.due_date, "%b %-d")}
                          </span>
                          <span class="badge badge-ghost badge-sm">
                            <.icon name="hero-bars-3-bottom-left" class="size-3 mr-1" /> {length(
                              task.children
                            )}
                          </span>
                        </div>
                      </div>
                      <div :if={task.children != []} class="mt-2 space-y-2">
                        <div class="flex items-center gap-1 text-xs font-medium opacity-70">
                          <.icon name="hero-bars-3-bottom-left" class="size-3" /> Subtasks
                        </div>
                        <div class="flex items-center gap-2">
                          <div class="h-[6px] grow bg-base-300/70 rounded overflow-hidden">
                            <div
                              class="h-full bg-primary/70 transition-all"
                              style={"width: #{subtask_completion(task.children)}%"}
                            />
                          </div>
                          <span class="text-[10px] font-medium tabular-nums opacity-70 shrink-0 whitespace-nowrap">
                            {done_children_count(task.children)} / {length(task.children)}
                          </span>
                        </div>
                        <div class="space-y-1">
                          <%= for child <- Enum.take(sorted_children(task.children), 3) do %>
                            <div
                              id={"task-" <> child.id <> "-mini"}
                              class="group flex items-center gap-2 rounded border border-base-300/70 hover:border-primary/50 px-2 py-1 text-sm bg-base-100/60"
                            >
                              <button
                                type="button"
                                phx-click={JS.push("toggle_subtask", value: %{id: child.id})}
                                class={[
                                  "size-5 rounded border flex items-center justify-center",
                                  child.status == "done" &&
                                    "bg-primary text-primary-content border-primary",
                                  child.status != "done" && "bg-base-100 border-base-300"
                                ]}
                                aria-label={(child.status == "done" && "Mark undone") || "Mark done"}
                              >
                                <.icon :if={child.status == "done"} name="hero-check" class="size-4" />
                              </button>
                              <span class="truncate flex-1" title={child.name}>{child.name}</span>
                              <span :if={child.due_date} class="text-[10px] opacity-60">
                                {Calendar.strftime(child.due_date, "%b %-d")}
                              </span>
                              <button
                                type="button"
                                class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100 transition-opacity"
                                title="Edit subtask"
                                phx-click={JS.push("open_edit", value: %{id: child.id})}
                              >
                                <.icon name="hero-pencil" class="size-4" />
                              </button>
                            </div>
                          <% end %>
                          <div
                            :if={length(task.children) > 3}
                            class="flex items-center justify-between text-[10px]"
                          >
                            <span class="opacity-60">+{length(task.children) - 3} more</span>
                            <button
                              class="link link-hover text-[10px]"
                              phx-click={JS.navigate(~p"/groups/#{@course_group}/tasks/#{task}")}
                            >
                              View all
                            </button>
                          </div>
                          <button
                            class="btn btn-xs btn-ghost w-full mt-1"
                            phx-click={
                              JS.push("open_quick_new",
                                value: %{status: task.status, parent_id: task.id}
                              )
                            }
                          >
                            <.icon name="hero-plus" class="size-3" /> Add subtask
                          </button>
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
              const zones = Array.from(this.el.querySelectorAll('[data-drop-zone]'))

              const clearHighlights = () => zones.forEach(z => z.classList.remove('ring-2','ring-primary/50','ring-offset-1'))

              this.el.addEventListener('dragstart', (e) => {
                const card = e.target.closest('[data-task-id]')
                if(!card) return
                this.dragged = card
                e.dataTransfer?.setData('text/plain', card.dataset.taskId)
                if(e.dataTransfer){ e.dataTransfer.effectAllowed = 'move' }
                e.dataTransfer?.setDragImage(card, 10, 10)
              })

              this.el.addEventListener('dragend', () => { this.dragged = null; clearHighlights() })

              zones.forEach(zone => {
                zone.addEventListener('dragover', (e) => { e.preventDefault(); if(!zone.classList.contains('ring-2')){ zone.classList.add('ring-2','ring-primary/50','ring-offset-1') } })
                zone.addEventListener('dragenter', (e) => { if(e.dataTransfer){ e.dataTransfer.dropEffect = 'move' } zone.classList.add('ring-2','ring-primary/50','ring-offset-1') })
                zone.addEventListener('dragleave', () => { zone.classList.remove('ring-2','ring-primary/50','ring-offset-1') })
                zone.addEventListener('drop', (e) => {
                  e.preventDefault()
                  const taskId = this.dragged?.dataset.taskId || e.dataTransfer?.getData('text/plain')
                  const status = zone.dataset.status || null
                  clearHighlights()
                  if(taskId && status){ this.pushEvent('kanban:move', {task_id: taskId, status: status}) }
                })
              })
            }
          }
        </script>
      <% end %>

      <div
        :if={@show_edit}
        id="edit-modal"
        class="fixed inset-0 z-50 hidden"
        phx-mounted={show("#edit-modal")}
        phx-remove={hide("#edit-modal")}
      >
        <div class="absolute inset-0 bg-base-300/40" phx-click={JS.push("close_edit")} />
        <div class="modal modal-open">
          <div class="modal-box space-y-3">
            <h3 class="font-bold text-lg">Edit task</h3>
            <.form for={@edit_form} id="edit-form" phx-submit="save_edit">
              <.input type="text" field={@edit_form[:name]} label="Title" required />
              <.input type="textarea" field={@edit_form[:description]} label="Description" />
              <.input
                type="select"
                field={@edit_form[:assignee_id]}
                prompt="Unassigned"
                options={@assignee_options}
                label="Assigned to"
              />
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                <.input
                  type="select"
                  field={@edit_form[:priority]}
                  options={priority_options()}
                  label="Priority"
                />
                <.input type="date" field={@edit_form[:due_date]} label="Due date" />
              </div>
              <.input
                type="select"
                field={@edit_form[:status]}
                options={status_options()}
                label="Status"
              />
              <.input
                type="select"
                field={@edit_form[:parent_id]}
                prompt="No parent"
                options={@edit_parent_options}
                label="Parent task"
              />
              <footer class="flex gap-2 justify-end pt-2">
                <.button phx-click={JS.push("close_edit")} type="button">Cancel</.button>
                <.button variant="primary" phx-disable-with="Saving...">Save</.button>
              </footer>
            </.form>
          </div>
        </div>
      </div>
      <div
        :if={@show_quick_new}
        id="quick-new"
        class="fixed inset-0 z-50 hidden"
        phx-mounted={show("#quick-new")}
        phx-remove={hide("#quick-new")}
      >
        <div class="absolute inset-0 bg-base-300/40" phx-click={JS.push("close_quick_new")} />
        <div class="modal modal-open">
          <div class="modal-box space-y-3">
            <h3 class="font-bold text-lg">Quick create task</h3>
            <.form for={@quick_form} id="quick-form" phx-submit="quick_create">
              <.input type="text" field={@quick_form[:name]} label="Title" required />
              <.input type="textarea" field={@quick_form[:description]} label="Description" />
              <.input
                type="select"
                field={@quick_form[:assignee_id]}
                prompt="Unassigned"
                options={@assignee_options}
                label="Assigned to"
              />
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                <.input
                  type="select"
                  field={@quick_form[:priority]}
                  options={priority_options()}
                  label="Priority"
                />
                <.input type="date" field={@quick_form[:due_date]} label="Due date" />
              </div>
              <.input
                type="select"
                field={@quick_form[:parent_id]}
                prompt="No parent"
                options={@parent_options}
                label="Parent task"
              />
              <footer class="flex gap-2 justify-end pt-2">
                <.button phx-click={JS.push("close_quick_new")} type="button">Cancel</.button>
                <.button variant="primary" phx-disable-with="Creating...">Create</.button>
              </footer>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"group_id" => group_id}, _session, socket) do
    if connected?(socket) do
      Courses.subscribe_group_tasks(group_id)
    end

    course_group = Courses.get_course_group!(socket.assigns.current_scope, group_id)

    user_view =
      case socket.assigns.current_scope.user.preferred_task_view do
        "board" -> :board
        _ -> :list
      end

    tasks = list_tasks(socket.assigns.current_scope, group_id)
    stats = compute_stats(tasks)
    filters = default_filters()
    sort = "priority_desc"
    members = Courses.list_group_memberships(group_id)
    parent_opts = parent_options(tasks)

    {:ok,
     socket
     |> assign(:page_title, "Listing Tasks")
     |> assign(:course_group, course_group)
     |> assign(:members, members)
     |> assign(:assignee_options, assignee_options(members))
     |> assign(:sort_options, sort_options())
     |> assign(:filters, filters)
     |> assign(:sort, sort)
     |> assign(:filter_form, to_form(Map.put(filters, "sort", sort), as: :f))
     |> assign(:view_mode, user_view)
     |> assign(:show_quick_new, false)
     |> assign(:show_edit, false)
     |> assign(:editing_task, nil)
     |> assign(:edit_form, to_form(%{}, as: :task))
     |> assign(:quick_status, "backlog")
     |> assign(:parent_options, parent_opts)
     |> assign(:edit_parent_options, parent_opts)
     |> assign(
       :quick_form,
       to_form(
         %{
           "name" => nil,
           "description" => nil,
           "assignee_id" => nil,
           "priority" => "medium",
           "due_date" => nil
         },
         as: :task
       )
     )
     |> assign(:task_stats, stats)
     |> assign_board(apply_filters_sort(tasks, filters, sort))
     |> stream(:tasks, apply_filters_sort(tasks, filters, sort))}
  end

  @impl true
  def handle_params(%{"view" => "list"}, _uri, socket) do
    _ = Accounts.update_preferred_task_view(socket.assigns.current_scope.user, "list")

    tasks = list_tasks(socket.assigns.current_scope, socket.assigns.course_group.id)
    stats = compute_stats(tasks)
    tasks = apply_filters_sort(tasks, socket.assigns.filters, socket.assigns.sort)
    parent_opts = parent_options(tasks)

    {:noreply,
     socket
     |> assign(:view_mode, :list)
     |> assign(:task_stats, stats)
     |> assign(:parent_options, parent_opts)
     |> assign(:edit_parent_options, parent_opts)
     |> stream(:tasks, tasks, reset: true)}
  end

  def handle_params(%{"view" => "board"}, _uri, socket) do
    _ = Accounts.update_preferred_task_view(socket.assigns.current_scope.user, "board")

    tasks = list_tasks(socket.assigns.current_scope, socket.assigns.course_group.id)
    stats = compute_stats(tasks)
    tasks = apply_filters_sort(tasks, socket.assigns.filters, socket.assigns.sort)
    parent_opts = parent_options(tasks)

    {:noreply,
     socket
     |> assign(:view_mode, :board)
     |> assign(:task_stats, stats)
     |> assign(:parent_options, parent_opts)
     |> assign(:edit_parent_options, parent_opts)
     |> assign_board(tasks)}
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

  def handle_event("kanban:move", %{"task_id" => id, "status" => status}, socket) do
    # Optimistic UI update: move immediately on the board, then persist async
    columns = socket.assigns.board_columns || []

    case move_task_between_columns(columns, id, status) do
      {:no_change, _columns} ->
        # Dropped in the same column or task not found; nothing to do
        {:noreply, socket}

      {:moved, new_columns, old_status} ->
        # Recompute stats from the optimistic board state
        optimistic_tasks = flatten_board_tasks(new_columns)
        new_stats = compute_stats(optimistic_tasks)

        # Persist in the background; revert on failure
        parent = self()
        current_scope = socket.assigns.current_scope

        Task.start(fn ->
          task = Courses.get_task!(current_scope, id)

          case Courses.update_task(current_scope, task, %{status: status}) do
            {:ok, _} ->
              :ok

            {:error, _changeset} ->
              send(parent, {:kanban_move_revert, %{id: id, old_status: old_status}})
          end
        end)

        {:noreply,
         socket
         |> assign(:board_columns, new_columns)
         |> assign(:task_stats, new_stats)}
    end
  end

  # Toggle a subtask between done and todo
  def handle_event("toggle_subtask", %{"id" => id}, socket) do
    # Optimistic UI update similar to kanban drag
    case update_child_status_in_columns(socket.assigns.board_columns, id) do
      {:updated, new_columns, old_status, new_status} ->
        optimistic_tasks = flatten_board_tasks(new_columns)
        stats = compute_stats(optimistic_tasks)

        filtered =
          apply_filters_sort(optimistic_tasks, socket.assigns.filters, socket.assigns.sort)

        parent = self()
        current_scope = socket.assigns.current_scope

        Task.start(fn ->
          child = Courses.get_task!(current_scope, id)

          case Courses.update_task(current_scope, child, %{status: new_status}) do
            {:ok, _} ->
              :ok

            {:error, _cs} ->
              send(parent, {:subtask_toggle_revert, %{id: id, old_status: old_status}})
          end
        end)

        {:noreply,
         socket
         |> assign(:board_columns, new_columns)
         |> assign(:task_stats, stats)
         |> assign(:parent_options, parent_options(optimistic_tasks))
         |> assign(:edit_parent_options, parent_options(optimistic_tasks))
         |> stream(:tasks, filtered, reset: true)}

      :not_found ->
        {:noreply, socket}
    end
  end

  def handle_event("open_quick_new", %{"status" => status} = params, socket) do
    parent_id = Map.get(params, "parent_id")

    {:noreply,
     socket
     |> assign(:show_quick_new, true)
     |> assign(:quick_status, status)
     |> assign(
       :quick_form,
       to_form(
         %{
           "name" => nil,
           "description" => nil,
           "assignee_id" => nil,
           "priority" => "medium",
           "due_date" => nil,
           "parent_id" => parent_id
         },
         as: :task
       )
     )}
  end

  def handle_event("close_quick_new", _params, socket) do
    {:noreply, assign(socket, :show_quick_new, false)}
  end

  def handle_event("open_edit", %{"id" => id}, socket) do
    task = Courses.get_task!(socket.assigns.current_scope, id)

    changeset =
      task
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.cast(%{}, [
        :name,
        :description,
        :assignee_id,
        :priority,
        :due_date,
        :status
      ])

    {:noreply,
     socket
     |> assign(:show_edit, true)
     |> assign(:editing_task, task)
     |> assign(
       :edit_parent_options,
       parent_options(
         list_tasks(socket.assigns.current_scope, socket.assigns.course_group.id),
         task.id
       )
     )
     |> assign(:edit_form, to_form(changeset))}
  end

  def handle_event("close_edit", _params, socket) do
    {:noreply, socket |> assign(:show_edit, false) |> assign(:editing_task, nil)}
  end

  def handle_event("save_edit", %{"task" => params}, socket) do
    task = socket.assigns.editing_task

    case Courses.update_task(socket.assigns.current_scope, task, params) do
      {:ok, _task} ->
        tasks = list_tasks(socket.assigns.current_scope, socket.assigns.course_group.id)
        stats = compute_stats(tasks)
        tasks = apply_filters_sort(tasks, socket.assigns.filters, socket.assigns.sort)

        {:noreply,
         socket
         |> assign(:show_edit, false)
         |> assign(:editing_task, nil)
         |> assign(:task_stats, stats)
         |> assign_board(tasks)
         |> assign(:parent_options, parent_options(tasks))
         |> assign(:edit_parent_options, parent_options(tasks))
         |> stream(:tasks, tasks, reset: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, edit_form: to_form(changeset))}
    end
  end

  def handle_event("quick_create", %{"task" => params}, socket) do
    attrs =
      params
      |> Map.put("course_group_id", socket.assigns.course_group.id)
      |> Map.put("status", socket.assigns.quick_status)
      |> Map.update("priority", "medium", & &1)

    case Courses.create_task(socket.assigns.current_scope, attrs) do
      {:ok, _task} ->
        tasks = list_tasks(socket.assigns.current_scope, socket.assigns.course_group.id)
        stats = compute_stats(tasks)
        tasks = apply_filters_sort(tasks, socket.assigns.filters, socket.assigns.sort)

        {:noreply,
         socket
         |> assign(:show_quick_new, false)
         |> assign(:task_stats, stats)
         |> assign_board(tasks)
         |> assign(:parent_options, parent_options(tasks))
         |> assign(:edit_parent_options, parent_options(tasks))
         |> stream(:tasks, tasks, reset: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, quick_form: to_form(changeset))}
    end
  end

  def handle_event("filters", %{"f" => params}, socket) do
    filters = %{
      "assignee_id" => Map.get(params, "assignee_id", ""),
      "unassigned" => truthy?(Map.get(params, "unassigned")),
      "q" => Map.get(params, "q", ""),
      "sort" => Map.get(params, "sort", "priority_desc")
    }

    tasks = list_tasks(socket.assigns.current_scope, socket.assigns.course_group.id)
    stats = compute_stats(tasks)
    # pass sort string as needed
    tasks = apply_filters_sort(tasks, filters, filters["sort"])

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:sort, filters["sort"])
     |> assign(:filter_form, to_form(filters, as: :f))
     |> assign(:task_stats, stats)
     |> assign_board(tasks)
     |> assign(:parent_options, parent_options(tasks))
     |> assign(:edit_parent_options, parent_options(tasks))
     |> stream(:tasks, tasks, reset: true)}
  end

  @impl true
  def handle_info({type, %Studtasks.Courses.Task{}}, socket)
      when type in [:created, :updated, :deleted] do
    tasks = list_tasks(socket.assigns.current_scope, socket.assigns.course_group.id)
    stats = compute_stats(tasks)
    tasks = apply_filters_sort(tasks, socket.assigns.filters, socket.assigns.sort)

    {:noreply,
     socket
     |> assign(:task_stats, stats)
     |> assign_board(tasks)
     |> assign(:parent_options, parent_options(tasks))
     |> assign(:edit_parent_options, parent_options(tasks))
     |> stream(:tasks, tasks, reset: true)}
  end

  # Revert an optimistic drag if persistence fails
  def handle_info({:kanban_move_revert, %{id: id, old_status: old_status}}, socket) do
    columns = socket.assigns.board_columns || []

    case move_task_between_columns(columns, id, old_status) do
      {:no_change, _} ->
        {:noreply, put_flash(socket, :error, "Could not move task. Please try again.")}

      {:moved, reverted_columns, _from_status} ->
        tasks = flatten_board_tasks(reverted_columns)
        stats = compute_stats(tasks)

        {:noreply,
         socket
         |> put_flash(:error, "Could not move task. Change was reverted.")
         |> assign(:board_columns, reverted_columns)
         |> assign(:task_stats, stats)}
    end
  end

  # Revert an optimistic subtask toggle
  def handle_info({:subtask_toggle_revert, %{id: id, old_status: old_status}}, socket) do
    columns = socket.assigns.board_columns || []

    case revert_child_status_in_columns(columns, id, old_status) do
      {:reverted, new_columns} ->
        tasks = flatten_board_tasks(new_columns)
        stats = compute_stats(tasks)
        filtered = apply_filters_sort(tasks, socket.assigns.filters, socket.assigns.sort)

        {:noreply,
         socket
         |> put_flash(:error, "Could not update subtask. Change was reverted.")
         |> assign(:board_columns, new_columns)
         |> assign(:task_stats, stats)
         |> stream(:tasks, filtered, reset: true)}

      :not_found ->
        {:noreply, put_flash(socket, :error, "Subtask revert failed")}
    end
  end

  defp list_tasks(current_scope, group_id) do
    Courses.list_group_tasks(current_scope, group_id)
  end

  defp assign_board(socket, tasks) do
    # Build Kanban columns using ONLY root (parentless) tasks so subtasks
    # are displayed inside their parent's card and not as separate cards.
    # We still keep all tasks elsewhere (streams, stats) so list view and
    # metrics include subtasks.
    root_tasks = Enum.filter(tasks, &is_nil(&1.parent_id))
    grouped = Enum.group_by(root_tasks, & &1.status)
    statuses = ["backlog", "todo", "in_progress", "done"]

    columns = Enum.map(statuses, fn s -> {s, %{tasks: Map.get(grouped, s, [])}} end)

    assign(socket, board_columns: columns)
  end

  # Move a task by id from its current column to a new status column.
  # Returns:
  # {:no_change, columns} if task not found or already in that status
  # {:moved, new_columns, old_status}
  defp move_task_between_columns(columns, id, new_status) when is_list(columns) do
    # Find and remove task from its current column
    {found_task, old_status, stripped_columns} =
      Enum.reduce(columns, {nil, nil, []}, fn {status, %{tasks: tasks} = col}, {ft, os, acc} ->
        if ft do
          {ft, os, [{status, col} | acc]}
        else
          {maybe_task, remaining} = pop_task_by_id(tasks, id)

          if maybe_task do
            {maybe_task, status, [{status, %{col | tasks: remaining}} | acc]}
          else
            {nil, nil, [{status, col} | acc]}
          end
        end
      end)

    stripped_columns = Enum.reverse(stripped_columns)

    cond do
      is_nil(found_task) ->
        {:no_change, columns}

      old_status == new_status ->
        {:no_change, columns}

      true ->
        updated_task = Map.put(found_task, :status, new_status)

        new_columns =
          Enum.map(stripped_columns, fn {status, %{tasks: tasks} = col} ->
            if status == new_status do
              {status, %{col | tasks: tasks ++ [updated_task]}}
            else
              {status, col}
            end
          end)

        {:moved, new_columns, old_status}
    end
  end

  # Optimistically update a child's status inside board columns
  defp update_child_status_in_columns(columns, child_id) when is_list(columns) do
    {new_columns, result} =
      Enum.map_reduce(columns, :not_found, fn {status, %{tasks: tasks} = col}, acc ->
        {new_tasks, acc2} =
          Enum.map_reduce(tasks, acc, fn task, acc_in ->
            {new_children, hit, old_s, new_s} = toggle_child_status(task.children || [], child_id)
            new_task = if hit, do: %{task | children: new_children}, else: task
            acc_out = if hit and acc_in == :not_found, do: {:updated, old_s, new_s}, else: acc_in
            {new_task, acc_out}
          end)

        {{status, %{col | tasks: new_tasks}}, acc2}
      end)

    case result do
      {:updated, old_s, new_s} -> {:updated, new_columns, old_s, new_s}
      _ -> :not_found
    end
  end

  defp toggle_child_status(children, child_id) do
    Enum.map_reduce(children, {false, nil, nil}, fn ch, {hit, old_s, new_s} ->
      cond do
        hit ->
          {ch, {hit, old_s, new_s}}

        to_string(ch.id) == to_string(child_id) ->
          ns = if ch.status == "done", do: "todo", else: "done"
          {Map.put(ch, :status, ns), {true, ch.status, ns}}

        true ->
          {ch, {hit, old_s, new_s}}
      end
    end)
    |> (fn {updated_children, {hit, old_s, new_s}} -> {updated_children, hit, old_s, new_s} end).()
  end

  # Revert child status
  defp revert_child_status_in_columns(columns, child_id, old_status) when is_list(columns) do
    {new_columns, touched} =
      Enum.map_reduce(columns, false, fn {status, %{tasks: tasks} = col}, acc ->
        {new_tasks, acc2} =
          Enum.map_reduce(tasks, acc, fn task, acc_in ->
            {new_children, hit} =
              Enum.map_reduce(task.children || [], false, fn ch, acc_child ->
                if acc_child do
                  {ch, true}
                else
                  if to_string(ch.id) == to_string(child_id) do
                    {Map.put(ch, :status, old_status), true}
                  else
                    {ch, false}
                  end
                end
              end)

            new_task = if hit, do: %{task | children: new_children}, else: task
            {new_task, acc_in or hit}
          end)

        {{status, %{col | tasks: new_tasks}}, acc2}
      end)

    if touched, do: {:reverted, new_columns}, else: :not_found
  end

  # Pop a task by id from a list of tasks, returning {task | nil, remaining_tasks}
  defp pop_task_by_id(tasks, id) do
    idx = Enum.find_index(tasks, fn t -> to_string(t.id) == to_string(id) end)

    case idx do
      nil -> {nil, tasks}
      idx -> {Enum.at(tasks, idx), List.delete_at(tasks, idx)}
    end
  end

  defp flatten_board_tasks(columns) when is_list(columns) do
    # Return all tasks represented in the board INCLUDING subtasks so stats
    # remain accurate after optimistic updates.
    for {_status, %{tasks: tasks}} <- columns,
        task <- tasks,
        child <- [task] ++ (task.children || []) do
      child
    end
  end

  defp compute_stats(tasks) do
    # Count by status and compute completion percent
    total = length(tasks)
    by_status = Enum.frequencies_by(tasks, &(&1.status || ""))
    done = Map.get(by_status, "done", 0)
    backlog = Map.get(by_status, "backlog", 0)
    todo = Map.get(by_status, "todo", 0)
    in_progress = Map.get(by_status, "in_progress", 0)

    percent_done =
      if total == 0 do
        0
      else
        done
        |> Kernel.*(100)
        |> div(total)
      end

    %{
      total: total,
      done: done,
      backlog: backlog,
      todo: todo,
      in_progress: in_progress,
      percent_done: percent_done
    }
  end

  defp bar_width(_count, total) when total <= 0, do: 0

  defp bar_width(count, total) when is_integer(count) and is_integer(total) do
    count
    |> Kernel.*(100)
    |> div(total)
  end

  defp default_filters do
    %{"assignee_id" => "", "unassigned" => false, "q" => "", "sort" => "priority_desc"}
  end

  # sort is stored as a string like "priority_desc"

  defp assignee_options(members) do
    members
    |> Enum.map(&{&1.user.name || &1.user.email, &1.user.id})
    |> Enum.sort_by(fn {name, _id} -> String.downcase(name || "") end)
  end

  defp sort_options do
    [
      {"Priority ↓", "priority_desc"},
      {"Priority ↑", "priority_asc"},
      {"Due date ↑", "due_date_asc"},
      {"Due date ↓", "due_date_desc"},
      {"Created ↑", "created_asc"},
      {"Created ↓", "created_desc"}
    ]
  end

  defp priority_options(),
    do: [{"Low", "low"}, {"Medium", "medium"}, {"High", "high"}, {"Urgent", "urgent"}]

  defp status_options(),
    do: Enum.map(["backlog", "todo", "in_progress", "done"], &{format_status(&1), &1})

  # --- Subtask helpers for board UI ---
  defp done_children_count(children) when is_list(children) do
    Enum.count(children, &(&1.status == "done"))
  end

  defp subtask_completion(children) when is_list(children) do
    total = length(children)
    if total == 0, do: 0, else: div(done_children_count(children) * 100, total)
  end

  defp sorted_children(children) do
    # Sort children strictly by name (case-insensitive), nil names last
    Enum.sort_by(children, fn c ->
      name_key =
        case c.name do
          # push nil names to bottom
          nil -> "zzzzzz"
          name -> String.downcase(name)
        end

      name_key
    end)
  end

  defp apply_filters_sort(tasks, filters, sort) do
    tasks
    |> Enum.filter(fn t ->
      assignee_ok =
        cond do
          truthy?(filters["unassigned"]) -> is_nil(t.assignee_id)
          filters["assignee_id"] in [nil, ""] -> true
          true -> t.assignee_id == filters["assignee_id"]
        end

      q = (filters["q"] || "") |> String.downcase()

      q_ok =
        q == "" ||
          String.contains?(String.downcase(t.name || ""), q) ||
          String.contains?(String.downcase(t.description || ""), q)

      assignee_ok and q_ok
    end)
    |> Enum.sort_by(fn t -> sort_key(t, sort) end, sort_dir(sort))
  end

  defp sort_key(t, sort) do
    case sort do
      "priority_desc" -> priority_rank(t.priority)
      "priority_asc" -> priority_rank(t.priority)
      "due_date_asc" -> t.due_date || ~D[3000-01-01]
      "due_date_desc" -> t.due_date || ~D[1900-01-01]
      "created_asc" -> t.inserted_at
      "created_desc" -> t.inserted_at
      _ -> priority_rank(t.priority)
    end
  end

  defp sort_dir(sort) do
    case sort do
      "priority_desc" -> :desc
      "priority_asc" -> :asc
      "due_date_asc" -> :asc
      "due_date_desc" -> :desc
      "created_asc" -> :asc
      "created_desc" -> :desc
      _ -> :desc
    end
  end

  defp priority_rank(nil), do: 1
  defp priority_rank("low"), do: 0
  defp priority_rank("medium"), do: 1
  defp priority_rank("high"), do: 2
  defp priority_rank("urgent"), do: 3
  defp priority_rank(_), do: 1

  defp format_status("in_progress"), do: "In Progress"
  defp format_status("todo"), do: "Todo"
  defp format_status("backlog"), do: "Backlog"
  defp format_status("done"), do: "Done"
  defp format_status(other) when is_binary(other), do: String.capitalize(other)

  defp priority_badge_class("urgent"), do: "badge-error"
  defp priority_badge_class("high"), do: "badge-warning"
  defp priority_badge_class("medium"), do: "badge-info"
  defp priority_badge_class("low"), do: "badge-ghost"
  defp priority_badge_class(_), do: "badge-ghost"

  defp truthy?(val), do: val in [true, "true", "on", 1, "1"]

  # Build parent task options limited to tasks without a parent (root tasks).
  # Exclude the currently edited task if exclude_id provided to avoid self-reference.
  defp parent_options(tasks, exclude_id \\ nil) do
    tasks
    |> Enum.map(fn
      {_id, t} -> t
      t -> t
    end)
    |> Enum.filter(&is_nil(&1.parent_id))
    |> Enum.reject(fn t -> exclude_id && to_string(t.id) == to_string(exclude_id) end)
    |> Enum.map(fn t -> {t.name || "Task #{t.id}", t.id} end)
    |> Enum.sort_by(fn {name, _id} -> String.downcase(name || "") end)
  end
end
