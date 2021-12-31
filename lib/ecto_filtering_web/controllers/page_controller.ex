defmodule EctoFilteringWeb.PageController do
  use EctoFilteringWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
