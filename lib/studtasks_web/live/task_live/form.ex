defmodule StudtasksWeb.TaskLive.Form do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses
  alias Studtasks.Courses.Task

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage task records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="task-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
          <.input
            field={@form[:assignee_id]}
            type="select"
            label="Assigned to"
            prompt="Unassigned"
            options={@assignee_options}
          />
          <.input field={@form[:due_date]} type="date" label="Due date" />
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
          <.input field={@form[:status]} type="select" label="Status" options={status_options()} />
          <.input
            field={@form[:priority]}
            type="select"
            label="Priority"
            options={priority_options()}
          />
          <.input
            field={@form[:parent_id]}
            type="select"
            label="Parent task"
            prompt="No parent"
            options={@parent_options}
          />
        </div>
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Task</.button>
          <.button navigate={return_path(@current_scope, @course_group, @return_to, @task)}>
            Cancel
          </.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"group_id" => group_id} = params, _session, socket) do
    group = Courses.get_course_group!(socket.assigns.current_scope, group_id)
    members = Courses.list_group_memberships(group_id)
    parent_opts = parent_options(socket.assigns.current_scope, group.id)

    {:ok,
     socket
     |> assign(:course_group, group)
     |> assign(:assignee_options, assignee_options(members))
     |> assign(:parent_options, parent_opts)
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id, "group_id" => group_id}) do
    task = Courses.get_task_in_group!(socket.assigns.current_scope, id, group_id)
    parent_opts = parent_options(socket.assigns.current_scope, group_id, task.id)

    socket
    |> assign(:page_title, "Edit Task")
    |> assign(:task, task)
    |> assign(:parent_options, parent_opts)
    |> assign(:form, to_form(Courses.change_task(socket.assigns.current_scope, task)))
  end

  defp apply_action(socket, :new, _params) do
    task = %Task{user_id: socket.assigns.current_scope.user.id}
    parent_opts = parent_options(socket.assigns.current_scope, socket.assigns.course_group.id)

    socket
    |> assign(:page_title, "New Task")
    |> assign(:task, task)
    |> assign(:parent_options, parent_opts)
    |> assign(:form, to_form(Courses.change_task(socket.assigns.current_scope, task)))
  end

  @impl true
  def handle_event("validate", %{"task" => task_params}, socket) do
    changeset =
      Courses.change_task(socket.assigns.current_scope, socket.assigns.task, task_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"task" => task_params}, socket) do
    save_task(socket, socket.assigns.live_action, task_params)
  end

  defp save_task(socket, :edit, task_params) do
    case Courses.update_task(socket.assigns.current_scope, socket.assigns.task, task_params) do
      {:ok, task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task updated successfully")
         |> push_navigate(
           to:
             return_path(
               socket.assigns.current_scope,
               socket.assigns.course_group,
               socket.assigns.return_to,
               task
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_task(socket, :new, task_params) do
    params = Map.put(task_params, "course_group_id", socket.assigns.course_group.id)

    case Courses.create_task(socket.assigns.current_scope, params) do
      {:ok, task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task created successfully")
         |> push_navigate(
           to:
             return_path(
               socket.assigns.current_scope,
               socket.assigns.course_group,
               socket.assigns.return_to,
               task
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, course_group, "index", _task), do: ~p"/groups/#{course_group}/tasks"

  defp return_path(_scope, course_group, "show", task),
    do: ~p"/groups/#{course_group}/tasks/#{task}"

  defp assignee_options(members) do
    members
    |> Enum.map(&{&1.user.name || &1.user.email, &1.user.id})
    |> Enum.sort_by(fn {name, _id} -> String.downcase(name || "") end)
  end

  defp status_options,
    do: [
      {"Backlog", "backlog"},
      {"Todo", "todo"},
      {"In Progress", "in_progress"},
      {"Done", "done"}
    ]

  defp priority_options,
    do: [{"Low", "low"}, {"Medium", "medium"}, {"High", "high"}, {"Urgent", "urgent"}]

  defp parent_options(scope, course_group_id, exclude_id \\ nil) do
    Courses.list_group_tasks(scope, course_group_id)
    |> Enum.reject(&(&1.id == exclude_id))
    |> Enum.map(&{&1.name, &1.id})
    |> Enum.sort_by(fn {name, _id} -> String.downcase(name || "") end)
  end
end
