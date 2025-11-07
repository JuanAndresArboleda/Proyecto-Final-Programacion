defmodule Taxi.Application do
  use Application

  def start(_type, _args) do
    Taxi.Supervisor.start_link([])
  end
end
