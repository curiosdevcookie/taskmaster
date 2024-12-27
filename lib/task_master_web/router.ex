defmodule TaskMasterWeb.Router do
  use TaskMasterWeb, :router

  import TaskMasterWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TaskMasterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TaskMasterWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", TaskMasterWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:task_master, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TaskMasterWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", TaskMasterWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{TaskMasterWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", TaskMasterWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{TaskMasterWeb.UserAuth, :ensure_authenticated}] do
      live "/:current_user/users/settings", UserSettingsLive, :edit
      live "/:current_user/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      scope "/:current_user" do
        live "/tasks", TaskLive.TaskIndex, :index
        live "/tasks/new", TaskLive.TaskIndex, :new
        live "/tasks/:parent_id/new_subtask", TaskLive.TaskIndex, :new_subtask
        live "/tasks/:id/edit", TaskLive.TaskIndex, :edit
        live "/tasks/:id", TaskLive.TaskShow, :show
        live "/tasks/:id/show/edit", TaskLive.TaskShow, :edit

        live "/avatars", AvatarLive.AvatarIndex, :index
        live "/avatars/new", AvatarLive.AvatarIndex, :new
        live "/avatars/:id/edit", AvatarLive.AvatarIndex, :edit

        live "/avatars/:id", AvatarLive.AvatarShow, :show
        live "/avatars/:id/show/edit", AvatarLive.AvatarShow, :edit

        live "/highscore", HighScoreLive, :index

        live "/contacts", ContactLive.ContactIndex, :index
        live "/contacts/new", ContactLive.ContactIndex, :new
        live "/contacts/:id/edit", ContactLive.ContactIndex, :edit

        live "/contacts/:id", ContactLive.ContactShow, :show
        live "/contacts/:id/show/edit", ContactLive.ContactShow, :edit

        live "/uploads", AvatarLive.UploadLive, :index
      end
    end
  end

  scope "/", TaskMasterWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{TaskMasterWeb.UserAuth, :mount_current_user}],
      root_layout: {TaskMasterWeb.Layouts, :confirmation} do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
