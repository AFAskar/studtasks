defmodule StudtasksWeb.CourseGroupLive.Show do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses
  alias Phoenix.HTML

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%= if @show_join_banner do %>
        <div class="alert alert-info my-2">
          <span>You’re not a member; join via invite.</span>
        </div>
      <% end %>
      <.header>
        Course group {@course_group.name || @course_group.id}
        <:subtitle>Group details</:subtitle>
        <:actions>
          <.button navigate={~p"/groups"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <%= if @is_member do %>
            <.button navigate={~p"/groups/#{@course_group}/tasks"}>
              <.icon name="hero-list-bullet" /> View tasks
            </.button>
          <% end %>
          <%= if @is_owner do %>
            <.button variant="primary" navigate={~p"/groups/#{@course_group}/edit?return_to=show"}>
              <.icon name="hero-pencil-square" /> Edit group
            </.button>
          <% end %>
        </:actions>
      </.header>
      <%= if @is_owner do %>
        <div class="mt-6 card p-4 space-y-4">
          <div class="flex items-center justify-between gap-2">
            <h3 class="text-base font-semibold">Invite members</h3>
            <div class="flex items-center gap-2">
              <.button size="sm" phx-click="generate_invite">Generate link</.button>
              <.button
                size="sm"
                phx-hook=".CopyLink"
                disabled={is_nil(@invite_url)}
                data-clipboard-text={@invite_url}
              >
                <.icon name="hero-clipboard" /> Copy link
              </.button>
            </div>
          </div>
          <%= if @invite_url do %>
            <div class="space-y-2">
              <p class="text-sm break-all"><strong>Invite link:</strong> {@invite_url}</p>
              <div class="border rounded p-3 bg-base-200">
                {@invite_qr_svg}
              </div>
            </div>
          <% else %>
            <p class="text-sm opacity-70">No invite generated yet. Click “Generate link”.</p>
          <% end %>
        </div>
      <% end %>

      <.list>
        <:item title="Name">{@course_group.name}</:item>
        <:item title="Description">{@course_group.description}</:item>
        <:item :if={@is_owner} title="Members">
          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <div>
                <span class="font-medium">Owner</span>
                <span class="opacity-70">— {@owner_name}</span>
              </div>
              <span class="badge badge-primary">owner</span>
            </div>
            <%= for m <- @memberships do %>
              <div class="flex items-center justify-between">
                <div class="truncate">
                  <span class="opacity-80">{m.user.name || m.user.email}</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="badge">{m.role}</span>
                  <.button
                    size="sm"
                    variant="secondary"
                    phx-click="membership:set_role"
                    phx-value-user={m.user.id}
                    phx-value-role={if m.role == "admin", do: "member", else: "admin"}
                  >
                    {if m.role == "admin", do: "Demote", else: "Promote"}
                  </.button>
                  <.button
                    size="sm"
                    variant="danger"
                    phx-click="membership:remove"
                    phx-value-user={m.user.id}
                  >
                    Remove
                  </.button>
                </div>
              </div>
            <% end %>
          </div>
        </:item>
      </.list>

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
              }catch(_err){
                console.error("Clipboard copy failed")
              }
            }
            this.el.addEventListener("click", this.handleClick)
          },
          destroyed(){
            this.el.removeEventListener("click", this.handleClick)
          }
        }
      </script>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    scope = socket.assigns.current_scope

    if connected?(socket) do
      Courses.subscribe_course_groups(scope)
    end

    group = Courses.get_course_group_public!(id)
    is_owner = Courses.group_owner?(scope, group)
    is_member = is_owner or Courses.group_member?(scope, id)
    memberships = if is_owner, do: Courses.list_group_memberships(id), else: []

    {:ok,
     socket
     |> assign(:page_title, "Show Course group")
     |> assign(:invite_url, nil)
     |> assign(:invite_qr_svg, nil)
     |> assign(:course_group, group)
     |> assign(:is_owner, is_owner)
     |> assign(:is_member, is_member)
     |> assign(:show_join_banner, not is_member)
     |> assign(:memberships, memberships)
     |> assign(:owner_name, scope.user.name || scope.user.email)}
  end

  @impl true
  def handle_info(
        {:updated, %Studtasks.Courses.CourseGroup{id: id} = course_group},
        %{assigns: %{course_group: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :course_group, course_group)}
  end

  def handle_info(
        {:deleted, %Studtasks.Courses.CourseGroup{id: id}},
        %{assigns: %{course_group: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current course_group was deleted.")
     |> push_navigate(to: ~p"/groups")}
  end

  def handle_info({type, %Studtasks.Courses.CourseGroup{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_invite", _params, socket) do
    if not socket.assigns.is_owner do
      {:noreply, put_flash(socket, :error, "Only the owner can generate invite links.")}
    else
      token =
        Phoenix.Token.sign(StudtasksWeb.Endpoint, "group_invite", socket.assigns.course_group.id)

      url = StudtasksWeb.Endpoint.url() <> ~p"/invites/groups/#{token}"

      # Generate QR SVG with Eqrcode (if available)
      qr_svg =
        try do
          url
          |> EQRCode.encode()
          |> EQRCode.svg(viewbox: true)
          |> then(&HTML.raw(&1))
        rescue
          _ -> HTML.raw("<p>QR code unavailable.</p>")
        end

      {:noreply, assign(socket, invite_url: url, invite_qr_svg: qr_svg)}
    end
  end

  @impl true
  def handle_event("membership:set_role", %{"user" => user_id, "role" => role}, socket) do
    group = socket.assigns.course_group
    scope = socket.assigns.current_scope

    with true <- socket.assigns.is_owner,
         {:ok, _} <- Courses.set_group_membership_role(scope, group.id, user_id, role) do
      {:noreply, assign(socket, :memberships, Courses.list_group_memberships(group.id))}
    else
      _ -> {:noreply, put_flash(socket, :error, "Could not change role")}
    end
  end

  def handle_event("membership:remove", %{"user" => user_id}, socket) do
    group = socket.assigns.course_group
    scope = socket.assigns.current_scope

    with true <- socket.assigns.is_owner,
         :ok <- Courses.remove_group_member(scope, group.id, user_id) do
      {:noreply, assign(socket, :memberships, Courses.list_group_memberships(group.id))}
    else
      _ -> {:noreply, put_flash(socket, :error, "Could not remove member")}
    end
  end
end
