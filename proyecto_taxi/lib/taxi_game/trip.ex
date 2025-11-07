defmodule TaxiGame.Trip do
  use GenServer

  @file "data/trips.json"
  @duration 20_000

  def start_link(args), do: GenServer.start_link(__MODULE__, args)
  def list_trips, do: load_data()

  def create(user, origin, destination) do
    id = :erlang.unique_integer([:positive]) |> Integer.to_string()
    trip = %{id: id, user: user, origin: origin, destination: destination, driver: nil, status: "active"}

    data = load_data()
    save_data(data ++ [trip])

    GenServer.start_link(__MODULE__, trip)

    {:ok, id}
  end

  def assign_driver(id, driver) do
    trips = load_data()

    updated =
      Enum.map(trips, fn t ->
        if t.id == id, do: %{t | driver: driver, status: "assigned"}, else: t
      end)

    save_data(updated)
    {:ok, "Driver asignado a viaje #{id}"}
  end

  # Callbacks
  def init(trip) do
    Process.send_after(self(), :finish, @duration)
    {:ok, trip}
  end

  def handle_info(:finish, state) do
    trips = load_data()

    updated =
      Enum.map(trips, fn t ->
        if t.id == state.id, do: %{t | status: "completed"}, else: t
      end)

    save_data(updated)
    {:stop, :normal, state}
  end

  # JSON helpers
  defp load_data do
    unless File.exists?(@file), do: File.write!(@file, "[]")

    case File.read(@file) do
      {:ok, content} when content != "" -> Jason.decode!(content)
      _ -> []
    end
  end

  defp save_data(data) do
    File.write!(@file, Jason.encode!(data, pretty: true))
  end
end
