defmodule OrgchartWeb.PageController do
  use OrgchartWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
