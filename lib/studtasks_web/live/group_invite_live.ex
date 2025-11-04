defmodule StudtasksWeb.GroupInviteLive do
  use StudtasksWeb, :live_view

  alias Studtasks.Courses
  alias Studtasks.Repo
  alias Studtasks.Courses.CourseGroup

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Join Group
        <:subtitle>Accept an invitation to join this group.</:subtitle>
      </.header>

      <div class="space-y-4">
        <p><strong>Group:</strong> {@group.name}</p>
        <p class="opacity-80">{@group.description}</p>

        <%= if @current_scope.user do %>
          <.button phx-click="accept" phx-disable-with="Joining..." variant="primary">Join group</.button>
        <% else %>
          <div class="alert">
            Please log in to accept the invite, then revisit this link.
          </div>
          <.link navigate={~p"/users/log-in"} class="btn">Log in</.link>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    with {:ok, group_id} <- verify_token(token),
         true <- not is_nil(group_id),
         %CourseGroup{} = group <- Repo.get!(CourseGroup, group_id) do
      {:ok, assign(socket, token: token, group: group)}
    else
      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Invalid or expired invite link.")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("accept", _params, socket) do
    with %Studtasks.Accounts.Scope{user: user} <- socket.assigns.current_scope,
         true <- not is_nil(user),
         {:ok, _} <- Courses.ensure_group_membership(socket.assigns.current_scope, socket.assigns.group.id) do
      {:noreply,
       socket
       |> put_flash(:info, "You have joined the group.")
       |> push_navigate(to: ~p"/groups/#{socket.assigns.group}")}
    else
      _ -> {:noreply, put_flash(socket, :error, "Could not join the group.")}
    end
  end

  defp verify_token(token) do
    Phoenix.Token.verify(StudtasksWeb.Endpoint, "group_invite", token, max_age: 60 * 60 * 24 * 7)
  end
end
