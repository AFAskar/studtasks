defmodule StudtasksWeb.UserLive.ConfirmRequired do
  use StudtasksWeb, :live_view

  alias Studtasks.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-lg space-y-6">
        <div class="text-center">
          <.header>
            Please confirm your email
            <:subtitle>
              We sent a confirmation link to {@user_email}. You must confirm your email to use the app.
            </:subtitle>
          </.header>
        </div>

        <div :if={@dev_mailbox?} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>You are running in development mode.</p>
            <p>
              You can view sent emails at <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>
        </div>

        <.form for={%{}} id="resend_confirmation" phx-submit="resend">
          <.button class="btn btn-primary w-full" phx-disable-with="Sending...">
            Resend confirmation email
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     assign(socket,
       user_email: user && user.email,
       dev_mailbox?: dev_mailbox?()
     )}
  end

  @impl true
  def handle_event("resend", _params, socket) do
    if user = socket.assigns.current_scope.user do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    {:noreply,
     socket
     |> put_flash(
       :info,
       "If your email is in our system, you'll receive a confirmation email shortly."
     )}
  end

  defp dev_mailbox? do
    Application.get_env(:studtasks, :dev_routes) == true
  end
end
