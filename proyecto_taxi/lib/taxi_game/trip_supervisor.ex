defmodule TaxiGame.TripSupervisor do
  use DynamicSupervisor

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_trip(args) do
    DynamicSupervisor.start_child(__MODULE__, {TaxiGame.Trip, args})
  end
end
