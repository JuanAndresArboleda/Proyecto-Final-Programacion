defmodule Taxi.Supervisor do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      {Taxi.UserManager, []},
      {Taxi.Location, []},
      {Taxi.Server, []},
      {DynamicSupervisor, strategy: :one_for_one, name: Taxi.TripSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
