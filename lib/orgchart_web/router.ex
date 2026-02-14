defmodule OrgchartWeb.Router do
  use OrgchartWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OrgchartWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OrgchartWeb do
    pipe_through :browser

    live "/", OrgchartLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", OrgchartWeb do
  #   pipe_through :api
  # end
end
