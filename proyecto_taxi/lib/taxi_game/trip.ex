defmodule TaxiGame.Trip do
  use GenServer
  require Logger

  @data_dir "data"
  @data_file Path.join(@data_dir, "trips.json")

  # Public API
  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
  def create(user, origin, destination), do: GenServer.call(__MODULE__, {:create, user, origin, destination})
  def list_trips, do: GenServer.call(__MODULE__, :list)
  def assign_driver(trip_id, driver), do: GenServer.call(__MODULE__, {:assign, trip_id, driver})
  def complete_trip(trip_id), do: GenServer.call(__MODULE__, {:complete, trip_id})

  # GenServer callbacks
  def init(_) do
    ensure_file_exists()
    {:ok, load_data()}
  end

  def handle_call(:list, _from, state), do: {:reply, state, state}

  def handle_call({:create, user, origin, destination}, _from, trips) do
    # Verificar viajes duplicados pendientes
    if Enum.any?(trips, fn t -> t.origin == origin and t.destination == destination and Map.get(t, :status, :pendiente) != :completado end) do
      {:reply, {:error, :duplicate_trip}, trips}
    else
      id = System.unique_integer([:positive])
      new_trip = %{
        id: id,
        user: user,
        origin: origin,
        destination: destination,
        driver: nil,
        status: :pendiente,
        duration: nil
      }
      new_state = trips ++ [new_trip]
      save_data(new_state)
      {:reply, {:ok, id}, new_state}
    end
  end

  def handle_call({:assign, id, driver}, _from, state) do
    new_state =
      Enum.map(state, fn trip ->
        if trip.id == id do
          %{trip | driver: driver, status: :asignado}
        else
          trip
        end
      end)

    save_data(new_state)
    {:reply, :ok, new_state}
  end

  def handle_call({:complete, id}, _from, state) do
    new_state =
      Enum.map(state, fn trip ->
        if trip.id == id do
          duration = :rand.uniform(30) + 10
          %{trip | status: :completado, duration: duration}
        else
          trip
        end
      end)

    save_data(new_state)
    {:reply, :ok, new_state}  # solo :ok para que Jason no falle
  end

  # Funciones internas
  defp ensure_file_exists do
    File.mkdir_p!(@data_dir)
    unless File.exists?(@data_file), do: File.write!(@data_file, "[]")
  end

  defp load_data do
    case File.read(@data_file) do
      {:ok, content} -> Jason.decode!(content, keys: :atoms)
      {:error, reason} ->
        Logger.error("Error leyendo #{@data_file}: #{inspect(reason)}")
        []
    end
  rescue
    _ -> []
  end

  defp save_data(data) do
    File.write!(@data_file, Jason.encode!(data, pretty: true))
  end
end
