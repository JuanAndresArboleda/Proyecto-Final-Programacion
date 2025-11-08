defmodule TaxiGame.Trip do
  use GenServer

  @file Path.join(:code.priv_dir(:taxi_game), "trips.json")

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def create(user, origin, destination),
    do: GenServer.call(__MODULE__, {:create, user, origin, destination})

  def list_trips(), do: GenServer.call(__MODULE__, :list)

  def assign_driver(trip_id, driver),
    do: GenServer.call(__MODULE__, {:assign, trip_id, driver})

  def init(_) do
    ensure_file_exists()
    {:ok, load_data()}
  end

  def handle_call(:list, _from, state), do: {:reply, state, state}

  def handle_call({:create, user, origin, destination}, _from, trips) do
    id = System.unique_integer([:positive])
    new_trip = %{id: id, user: user, origin: origin, destination: destination, driver: nil}
    new_state = trips ++ [new_trip]
    save_data(new_state)
    {:reply, {:ok, id}, new_state}
  end

  def handle_call({:assign, id, driver}, _from, state) do
    new_state =
      Enum.map(state, fn trip ->
        if trip.id == id, do: %{trip | driver: driver}, else: trip
      end)

    save_data(new_state)
    {:reply, :ok, new_state}
  end

  defp ensure_file_exists do
    unless File.exists?(@file) do
      File.write!(@file, "[]")
    end
  end

  defp load_data do
    {:ok, content} = File.read(@file)
    Jason.decode!(content)
  rescue
    _ -> []
  end

  defp save_data(data) do
    File.write!(@file, Jason.encode!(data, pretty: true))
  end
end
