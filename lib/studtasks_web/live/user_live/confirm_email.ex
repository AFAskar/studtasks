defmodule StudtasksWeb.UserLive.ConfirmEmail do
  use StudtasksWeb, :live_view

  alias Studtasks.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>Confirm your email</.header>
        </div>

        <.form
          :if={@user && !@user.confirmed_at}
          for={@form}
          id="confirmation_form"
          phx-mounted={JS.focus_first()}
          phx-submit="submit"
          action={~p"/users/confirm"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <.button
            name={@form[:remember_me].name}
            value="true"
            phx-disable-with="Confirming..."
            class="btn btn-primary w-full"
          >
            Confirm and stay logged in
          </.button>
          <.button phx-disable-with="Confirming..." class="btn btn-primary btn-soft w-full mt-2">
            Confirm and log in only this time
          </.button>
        </.form>

        <div :if={!@user} class="alert alert-warning mt-6">
          The confirmation link is invalid or it has expired.
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Accounts.get_user_by_confirm_token(token) do
      %{} = user ->
        form = to_form(%{"token" => token}, as: "user")

        {:ok, assign(socket, user: user, form: form, trigger_submit: false),
         temporary_assigns: [form: nil]}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Confirmation link is invalid or it has expired.")
         |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
