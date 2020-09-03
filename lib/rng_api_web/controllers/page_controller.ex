defmodule RngApiWeb.PageController do
  use RngApiWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
