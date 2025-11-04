defmodule StudtasksWeb.CourseGroupLive.Show do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses
  alias Phoenix.HTML

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Course group {@course_group.id}
        <:subtitle>This is a course_group record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/groups"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button navigate={~p"/groups/#{@course_group}/tasks"}>
            <.icon name="hero-list-bullet" /> View tasks
          </.button>
          <.button variant="primary" navigate={~p"/groups/#{@course_group}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit course_group
          </.button>
        </:actions>
      </.header>
      <div class="mt-6 card p-4 space-y-4">
        <div class="flex items-center justify-between">
          <h3 class="text-base font-semibold">Invite members</h3>
          <.button size="sm" phx-click="generate_invite">Generate link</.button>
        </div>
        <%= if @invite_url do %>
          <div class="space-y-2">
            <p class="text-sm break-all"><strong>Invite link:</strong> {@invite_url}</p>
            <div class="border rounded p-3 bg-base-200" phx-no-curly-interpolation>
              {@invite_qr_svg}
            </div>
          </div>
        <% else %>
          <p class="text-sm opacity-70">No invite generated yet. Click “Generate link”.</p>
        <% end %>
      </div>

      <.list>
        <:item title="Name">{@course_group.name}</:item>
        <:item title="Description">{@course_group.description}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Courses.subscribe_course_groups(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Course group")
     |> assign(:invite_url, nil)
     |> assign(:invite_qr_svg, nil)
     |> assign(:course_group, Courses.get_course_group!(socket.assigns.current_scope, id))}
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
    token = Phoenix.Token.sign(StudtasksWeb.Endpoint, "group_invite", socket.assigns.course_group.id)
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
