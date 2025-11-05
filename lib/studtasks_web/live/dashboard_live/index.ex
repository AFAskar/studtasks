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
            <.button variant="primary" phx-click={JS.push("open_new_group")}>
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
          row_click={
            fn {_id, course_group} -> JS.push("open_group", value: %{id: course_group.id}) end
          }
        >
          <:col :let={{_id, course_group}} label="Name">{course_group.name}</:col>
          <:col :let={{_id, course_group}} label="Description">{course_group.description}</:col>
          <:action :let={{_id, course_group}}>
            <.link navigate={~p"/groups/#{course_group}/tasks"}>Tasks</.link>
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

      <div
        :if={@show_new_group}
        id="new-group-modal"
        class="fixed inset-0 z-50 hidden"
        phx-mounted={show("#new-group-modal")}
        phx-remove={hide("#new-group-modal")}
      >
        <div class="absolute inset-0 bg-base-300/40" phx-click={JS.push("close_new_group")} />
        <div class="modal modal-open">
          <div class="modal-box space-y-3">
            <h3 class="font-bold text-lg">Create a new group</h3>
            <.form for={@group_form} id="group-form" phx-submit="create_group">
              <.input type="text" field={@group_form[:name]} label="Name" required />
              <.input type="textarea" field={@group_form[:description]} label="Description" required />
              <footer class="flex gap-2 justify-end pt-2">
                <.button type="button" phx-click={JS.push("close_new_group")}>Cancel</.button>
                <.button variant="primary" phx-disable-with="Creating...">Create</.button>
              </footer>
            </.form>
          </div>
        </div>
      </div>
      <div
        :if={@show_group}
        id="group-modal"
        class="fixed inset-0 z-50 hidden"
        phx-mounted={show("#group-modal")}
        phx-remove={hide("#group-modal")}
      >
        <div class="absolute inset-0 bg-base-300/40" phx-click={JS.push("close_group")} />
        <div class="modal modal-open">
          <div class="modal-box space-y-3 max-w-3xl">
            <div class="flex items-center justify-between">
              <h3 class="font-bold text-lg">Group details</h3>
              <.button type="button" phx-click={JS.push("close_group")}>Close</.button>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="space-y-2">
                <h4 class="font-semibold">Edit</h4>
                <.form for={@group_edit_form} id="group-edit-form" phx-submit="group:update">
                  <.input
                    type="text"
                    field={@group_edit_form[:name]}
                    label="Name"
                    disabled={!@is_owner}
                  />
                  <.input
                    type="textarea"
                    field={@group_edit_form[:description]}
                    label="Description"
                    disabled={!@is_owner}
                  />
                  <footer class="flex gap-2 justify-end pt-2">
                    <.button :if={@is_owner} variant="primary" phx-disable-with="Saving...">
                      Save
                    </.button>
                  </footer>
                </.form>
              </div>
              <div class="space-y-2">
                <h4 class="font-semibold">Invite</h4>
                <div class="flex items-center gap-2">
                  <.button phx-click={JS.push("group:generate_invite")} disabled={!@is_owner}>
                    Generate link
                  </.button>
                  <.button
                    phx-hook=".CopyLink"
                    disabled={is_nil(@invite_url)}
                    data-clipboard-text={@invite_url}
                  >
                    <.icon name="hero-clipboard" /> Copy link
                  </.button>
                </div>
                <%= if @invite_url do %>
                  <p class="text-sm break-all"><strong>Invite link:</strong> {@invite_url}</p>
                  <div class="border rounded p-3 bg-base-200">{@invite_qr_svg}</div>
                <% else %>
                  <p class="text-sm opacity-70">No invite generated yet. Click “Generate link”.</p>
                <% end %>
              </div>
            </div>
            <div class="space-y-2">
              <h4 class="font-semibold">Members</h4>
              <div class="space-y-2">
                <%= for m <- @memberships do %>
                  <div class="flex items-center justify-between">
                    <div class="truncate">
                      <span class="opacity-80">{m.user.name || m.user.email}</span>
                    </div>
                    <div class="flex items-center gap-2">
                      <span class="badge">{m.role}</span>
                      <.button
                        :if={@is_owner}
                        phx-click="membership:set_role"
                        phx-value-user={m.user.id}
                        phx-value-role={if m.role == "admin", do: "member", else: "admin"}
                      >
                        {if m.role == "admin", do: "Demote", else: "Promote"}
                      </.button>
                      <.button
                        :if={@is_owner}
                        phx-click="membership:remove"
                        phx-value-user={m.user.id}
                      >
                        Remove
                      </.button>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
            <script :type={Phoenix.LiveView.ColocatedHook} name=".CopyLink">
              export default {
                mounted(){
                  this.handleClick = async (e) => {
                    e.preventDefault()
                    const text = this.el.dataset.clipboardText
                    if(!text) return
                    try{
                      await navigator.clipboard.writeText(text)
                      this.el.classList.add("btn-success")
                      const original = this.el.innerHTML
                      this.el.innerHTML = '<span class="inline-flex items-center gap-1">✅ Copied</span>'
                      setTimeout(() => { this.el.innerHTML = original; this.el.classList.remove("btn-success") }, 1200)
                    }catch(_err){ console.error("Clipboard copy failed") }
                  }
                  this.el.addEventListener("click", this.handleClick)
                },
                destroyed(){ this.el.removeEventListener("click", this.handleClick) }
              }
            </script>
          </div>
        </div>
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
     |> assign(:show_new_group, false)
     |> assign(:group_form, new_group_form(socket.assigns.current_scope))
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

  @impl true
  def handle_event("open_group", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    group = Courses.get_course_group!(scope, id)
    memberships = Courses.list_group_memberships(id)
    is_owner = Courses.group_owner?(scope, group)

    {:noreply,
     socket
     |> assign(:show_group, true)
     |> assign(:selected_group, group)
     |> assign(:memberships, memberships)
     |> assign(:is_owner, is_owner)
     |> assign(:invite_url, nil)
     |> assign(:invite_qr_svg, nil)
     |> assign(:group_edit_form, group_edit_form(scope, group))}
  end

  def handle_event("close_group", _params, socket) do
    {:noreply, assign(socket, :show_group, false)}
  end

  def handle_event("group:update", %{"course_group" => params}, socket) do
    scope = socket.assigns.current_scope
    group = socket.assigns.selected_group

    case Courses.update_course_group(scope, group, params) do
      {:ok, group} ->
        groups = list_course_groups(scope)

        {:noreply,
         socket
         |> assign(:selected_group, group)
         |> assign(:group_edit_form, group_edit_form(scope, group))
         |> stream(:course_groups, groups, reset: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :group_edit_form, to_form(changeset))}
    end
  end

  def handle_event("group:generate_invite", _params, socket) do
    token =
      Phoenix.Token.sign(StudtasksWeb.Endpoint, "group_invite", socket.assigns.selected_group.id)

    url = StudtasksWeb.Endpoint.url() <> ~p"/invites/groups/#{token}"

    qr_svg =
      try do
        url |> EQRCode.encode() |> EQRCode.svg(viewbox: true) |> Phoenix.HTML.raw()
      rescue
        _ -> Phoenix.HTML.raw("<p>QR code unavailable.</p>")
      end

    {:noreply, assign(socket, invite_url: url, invite_qr_svg: qr_svg)}
  end

  def handle_event("membership:set_role", %{"user" => user_id, "role" => role}, socket) do
    scope = socket.assigns.current_scope
    group = socket.assigns.selected_group
    {:ok, _} = Courses.set_group_membership_role(scope, group.id, user_id, role)
    {:noreply, assign(socket, :memberships, Courses.list_group_memberships(group.id))}
  end

  def handle_event("membership:remove", %{"user" => user_id}, socket) do
    scope = socket.assigns.current_scope
    group = socket.assigns.selected_group
    :ok = Courses.remove_group_member(scope, group.id, user_id)
    {:noreply, assign(socket, :memberships, Courses.list_group_memberships(group.id))}
  end

  @impl true
  def handle_event("open_new_group", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_new_group, true)
     |> assign(:group_form, new_group_form(socket.assigns.current_scope))}
  end

  def handle_event("close_new_group", _params, socket) do
    {:noreply, assign(socket, :show_new_group, false)}
  end

  def handle_event("create_group", %{"course_group" => params}, socket) do
    case Courses.create_course_group(socket.assigns.current_scope, params) do
      {:ok, _group} ->
        groups = list_course_groups(socket.assigns.current_scope)

        {:noreply,
         socket
         |> assign(:show_new_group, false)
         |> assign(:group_count, length(groups))
         |> stream(:course_groups, groups, reset: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :group_form, to_form(changeset))}
    end
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

  defp new_group_form(scope) do
    Courses.change_course_group(scope, %Studtasks.Courses.CourseGroup{})
    |> to_form()
  end

  defp group_edit_form(scope, group) do
    Courses.change_course_group(scope, group)
    |> to_form()
  end
end
