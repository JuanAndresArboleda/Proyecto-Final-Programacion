defmodule TaxiGame.Location do
  use GenServer

  @file "data/locations.json"

  # --------- API ---------

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def list_locations do
    GenServer.call(__MODULE__, :list)
  end

  def add_location(location) do
    GenServer.call(__MODULE__, {:add, location})
  end

  # --------- GEN SERVER ---------

  @impl true
  def init(_state) do
    {:ok, load_locations()}
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:add, location}, _from, state) do
    new_state = state ++ [location]
    save_locations(new_state)
    {:reply, :ok, new_state}
  end

  # --------- FILE I/O ---------

  defp load_locations do
    # Asegura que la carpeta exista
    File.mkdir_p!("data")

    # Si el archivo no existe, créalo con []
    unless File.exists?(@file) do
      File.write!(@file, "[]")
    end

    case File.read(@file) do
      {:ok, content} when content != "" ->
        case Jason.decode(content) do
          {:ok, data} -> data
          _ -> []
        end

      {:ok, ""} ->
        []  # archivo vacío

      {:error, reason} ->
        IO.puts("Error leyendo archivo: #{inspect(reason)}")
        []
    end
  end

  defp save_locations(locations) do
    File.write!(@file, Jason.encode!(locations, pretty: true))
  end
end
