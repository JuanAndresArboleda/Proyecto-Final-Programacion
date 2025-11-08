defmodule TaxiGame.Location do
  use GenServer

  @file_path "data/locations.json"
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def list_locations do
    GenServer.call(__MODULE__, :list)
  end

  def add_location(location) do
    GenServer.call(__MODULE__, {:add, location})
  end

  #Callbacks
  def init(_state) do
    ensure_file_exists()
    {:ok, load_from_file()}
  end

  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add, location}, _from, state) do
    new_state = state ++ [location]
    save_to_file(new_state)
    {:reply, :ok, new_state}
  end

  #Persistencia
  defp ensure_file_exists do
    File.mkdir_p!("data")

    unless File.exists?(@file_path) do
      File.write!(@file_path, "[]")
    end
  end

  defp load_from_file do
    case File.read(@file_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} -> data
          _ -> []
        end

      _ ->
        []
    end
  end

  defp save_to_file(data) do
    File.write!(@file_path, Jason.encode!(data, pretty: true))
  end
end
