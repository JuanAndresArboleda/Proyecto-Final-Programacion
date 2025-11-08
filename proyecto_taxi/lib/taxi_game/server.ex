defmodule TaxiGame.Server do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def connect(username, password),
    do: GenServer.call(__MODULE__, {:connect, username, password})

  def request_trip(user, origin, destination),
    do: GenServer.call(__MODULE__, {:request_trip, user, origin, destination})

  def list_trips, do: GenServer.call(__MODULE__, :list_trips)

  def accept_trip(driver, trip_id),
    do: GenServer.call(__MODULE__, {:accept_trip, driver, trip_id})

  def init(state), do: {:ok, state}

  def handle_call({:connect, username, password}, _from, state) do
    {:reply, TaxiGame.UserManager.login_or_register(username, password), state}
  end

  def handle_call({:request_trip, user, origin, destination}, _from, state) do
    {:reply, TaxiGame.Trip.create(user, origin, destination), state}
  end

  def handle_call(:list_trips, _from, state) do
    {:reply, TaxiGame.Trip.list_trips(), state}
  end

  def handle_call({:accept_trip, driver, trip_id}, _from, state) do
    {:reply, TaxiGame.Trip.assign_driver(trip_id, driver), state}
  end
end
