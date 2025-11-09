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
          <.button variant="primary" phx-click={JS.push("open_edit")}>
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
        <:item :if={@task.parent} title="Parent task">
          <.link navigate={~p"/groups/#{@course_group}/tasks/#{@task.parent}"}>
            {@task.parent.name}
          </.link>
        </:item>
      </.list>

      <div :if={@task.children != []} class="mt-6">
        <h3 class="text-sm font-semibold mb-2">Subtasks</h3>
        <ul class="space-y-1">
          <%= for child <- @task.children do %>
            <li>
              <.link navigate={~p"/groups/#{@course_group}/tasks/#{child}"}>{child.name}</.link>
            </li>
          <% end %>
        </ul>
      </div>
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
              <footer class="flex gap-2 justify-end pt-2">
                <.button phx-click={JS.push("close_edit")} type="button">Cancel</.button>
                <.button variant="primary" phx-disable-with="Saving...">Save</.button>
              </footer>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id, "group_id" => group_id}, _session, socket) do
    if connected?(socket) do
      Courses.subscribe_group_tasks(group_id)
    end

    task = Courses.get_task_in_group!(socket.assigns.current_scope, id, group_id)
    members = Courses.list_group_memberships(group_id)

    {:ok,
     socket
     |> assign(:page_title, "Show Task")
     |> assign(:course_group, Courses.get_course_group!(socket.assigns.current_scope, group_id))
     |> assign(:task, task)
     |> assign(:members, members)
     |> assign(:assignee_options, assignee_options(members))
     |> assign(:show_edit, false)
     |> assign(:edit_form, to_form(%{}, as: :task))}
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

  @impl true
  def handle_event("open_edit", _params, socket) do
    task = socket.assigns.task

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

    {:noreply, socket |> assign(:show_edit, true) |> assign(:edit_form, to_form(changeset))}
  end

  def handle_event("close_edit", _params, socket) do
    {:noreply, assign(socket, :show_edit, false)}
  end

  def handle_event("save_edit", %{"task" => params}, socket) do
    task = socket.assigns.task

    case Courses.update_task(socket.assigns.current_scope, task, params) do
      {:ok, task} ->
        {:noreply, socket |> assign(:task, task) |> assign(:show_edit, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :edit_form, to_form(changeset))}
    end
  end

  defp format_status("in_progress"), do: "In Progress"
  defp format_status("todo"), do: "Todo"
  defp format_status("backlog"), do: "Backlog"
  defp format_status("done"), do: "Done"
  defp format_status(other) when is_binary(other), do: String.capitalize(other)

  defp assignee_options(members) do
    members
    |> Enum.map(&{&1.user.name || &1.user.email, &1.user.id})
    |> Enum.sort_by(fn {name, _id} -> String.downcase(name || "") end)
  end

  defp priority_options(),
    do: [{"Low", "low"}, {"Medium", "medium"}, {"High", "high"}, {"Urgent", "urgent"}]

  defp status_options(),
    do: Enum.map(["backlog", "todo", "in_progress", "done"], &{format_status(&1), &1})
end
