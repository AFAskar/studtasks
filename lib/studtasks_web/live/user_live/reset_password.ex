defmodule StudtasksWeb.UserLive.ResetPassword do
  use StudtasksWeb, :live_view

  alias Studtasks.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>Reset your password</p>
            <:subtitle>Enter a new password for your account.</:subtitle>
          </.header>
        </div>

        <.form for={@form} id="reset-password-form" phx-submit="save">
          <.input
            field={@form[:password]}
            type="password"
            label="New password"
            autocomplete="new-password"
            required
          />
          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm password"
            autocomplete="new-password"
            required
          />
          <.button class="btn btn-primary w-full">Update password</.button>
        </.form>

        <div class="text-center">
          <.link navigate={~p"/users/log-in"} class="link">Back to log in</.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Accounts.get_user_by_reset_password_token(token) do
      %Accounts.User{} ->
        form = to_form(%{"password" => "", "password_confirmation" => ""}, as: "user")
        {:ok, assign(socket, token: token, form: form)}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "The reset link is invalid or it has expired.")
         |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("save", %{"user" => attrs}, socket) do
    with %Accounts.User{} = user <-
           Accounts.get_user_by_reset_password_token(socket.assigns.token),
         {:ok, {_user, _expired}} <- Accounts.reset_user_password(user, attrs) do
      {:noreply,
       socket
       |> put_flash(:info, "Password updated successfully. You can now log in.")
       |> push_navigate(to: ~p"/users/log-in")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "user"))}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "The reset link is invalid or it has expired.")
         |> push_navigate(to: ~p"/users/log-in")}
    end
  end
end
