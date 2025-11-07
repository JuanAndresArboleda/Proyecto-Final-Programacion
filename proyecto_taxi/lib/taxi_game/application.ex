defmodule TaxiGame.Application do
  use Application

  def start(_type, _args) do
    children = [
      TaxiGame.UserManager,
      TaxiGame.Location,
      {DynamicSupervisor, name: TaxiGame.TripSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: TaxiGame.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
