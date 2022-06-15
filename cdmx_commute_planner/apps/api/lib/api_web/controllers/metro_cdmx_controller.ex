defmodule ApiWeb.MetroCdmxController do
  use ApiWeb, :controller

  def index(c, %{"origin" => origin, "dest" => dest}) do
    route =  Core.MetroCdmx.find_way(origin, dest)
    render(c, "routes.json", origin: origin, dest: dest, route: route)
  end
end
