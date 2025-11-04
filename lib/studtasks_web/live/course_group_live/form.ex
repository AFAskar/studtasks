defmodule StudtasksWeb.CourseGroupLive.Form do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses
  alias Studtasks.Courses.CourseGroup

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage course_group records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="course_group-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Course group</.button>
          <.button navigate={return_path(@current_scope, @return_to, @course_group)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    course_group = Courses.get_course_group!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Course group")
    |> assign(:course_group, course_group)
    |> assign(
      :form,
      to_form(Courses.change_course_group(socket.assigns.current_scope, course_group))
    )
  end

  defp apply_action(socket, :new, _params) do
    course_group = %CourseGroup{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Course group")
    |> assign(:course_group, course_group)
    |> assign(
      :form,
      to_form(Courses.change_course_group(socket.assigns.current_scope, course_group))
    )
  end

  @impl true
  def handle_event("validate", %{"course_group" => course_group_params}, socket) do
    changeset =
      Courses.change_course_group(
        socket.assigns.current_scope,
        socket.assigns.course_group,
        course_group_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"course_group" => course_group_params}, socket) do
    save_course_group(socket, socket.assigns.live_action, course_group_params)
  end

  defp save_course_group(socket, :edit, course_group_params) do
    case Courses.update_course_group(
           socket.assigns.current_scope,
           socket.assigns.course_group,
           course_group_params
         ) do
      {:ok, course_group} ->
        {:noreply,
         socket
         |> put_flash(:info, "Course group updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, course_group)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_course_group(socket, :new, course_group_params) do
    case Courses.create_course_group(socket.assigns.current_scope, course_group_params) do
      {:ok, course_group} ->
        {:noreply,
         socket
         |> put_flash(:info, "Course group created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, course_group)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _course_group), do: ~p"/groups"
  defp return_path(_scope, "show", course_group), do: ~p"/groups/#{course_group}"
end
