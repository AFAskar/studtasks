defmodule StudtasksWeb.Router do
  use StudtasksWeb, :router

  import StudtasksWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {StudtasksWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug StudtasksWeb.Plugs.SetLocale
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", StudtasksWeb do
    pipe_through :browser

    get "/", PageController, :home
    post "/locale", LocaleController, :update
  end

  # Other scopes may use custom stacks.
  # scope "/api", StudtasksWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:studtasks, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: StudtasksWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", StudtasksWeb do
    pipe_through [:browser, :require_authenticated_user, :require_confirmed_user]

    live_session :require_authenticated_user,
      on_mount: [
        {StudtasksWeb.UserAuth, :require_authenticated},
        {StudtasksWeb.UserAuth, :require_confirmed},
        {StudtasksWeb.UserAuth, :set_locale}
      ] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # Course dashboard (requires authentication)
      live "/dashboard", DashboardLive.Index, :index
      live "/dashboard/tasks", DashboardTasksLive, :index

      # Tasks nested under groups (requires authentication)
      live "/groups/:group_id/tasks", TaskLive.Index, :index
      live "/groups/:group_id/tasks/:id", TaskLive.Show, :show
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", StudtasksWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [
        {StudtasksWeb.UserAuth, :mount_current_scope},
        {StudtasksWeb.UserAuth, :set_locale}
      ] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/reset-password", UserLive.ForgotPassword, :new
      live "/users/reset-password/:token", UserLive.ResetPassword, :edit
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/users/confirm-required", UserLive.ConfirmRequired, :show
      # Group invite page (works with or without auth)
      live "/invites/groups/:token", GroupInviteLive, :show
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  # Routes that require authentication but allow unconfirmed users
  scope "/", StudtasksWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [
        {StudtasksWeb.UserAuth, :require_authenticated},
        {StudtasksWeb.UserAuth, :set_locale}
      ] do
      # Account confirmation requires the user to be logged in,
      # but they may still be unconfirmed at this point
      live "/users/confirm/:token", UserLive.ConfirmEmail, :new
    end

    post "/users/confirm", UserSessionController, :confirm
  end
end
