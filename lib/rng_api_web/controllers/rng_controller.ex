defmodule RngApiWeb.RNGController do
  use RngApiWeb, :controller

  def run(conn, _params) do
    {timestamp, users} = RngApi.NumberGenerator.run()

    render(conn, "run.json", %{timestamp: timestamp, users: users})
  end
end
