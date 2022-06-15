defmodule ApiWeb.MetroCdmxView do
  use ApiWeb, :view

  def render("routes.json", data) do
    %{origin: data.origin, dest: data.dest, itinerary: data.route, status: 200}
  end
end
