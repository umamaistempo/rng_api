defmodule RngApiWeb.RNGView do
  use RngApiWeb, :view

  def render("run.json", %{users: users, timestamp: timestamp}) do
    %{users: users, timestamp: timestamp}
  end
end
