defmodule StudtasksWeb.UserLive.ForgotPassword do
  use StudtasksWeb, :live_view

  alias Studtasks.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>Forgot your password?</p>
            <:subtitle>Enter your email and we'll send you a reset link.</:subtitle>
          </.header>
        </div>

        <.form for={@form} id="forgot-password-form" phx-submit="submit">
          <.input field={@form[:email]} type="email" label="Email" autocomplete="username" required />
          <.button class="btn btn-primary w-full">Send reset link</.button>
        </.form>

        <div class="text-center">
          <.link navigate={~p"/users/log-in"} class="link">Back to log in</.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{"email" => ""}, as: "user"))}
  end

  @impl true
  def handle_event("submit", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset-password/#{&1}")
      )
    end

    info = "If your email is in our system, you'll receive instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end
end
