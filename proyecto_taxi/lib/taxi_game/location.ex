defmodule TaxiGame.Location do
  use GenServer

  @file "data/locations.json"

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def list_locations, do: GenServer.call(__MODULE__, :list)

  def add_location(location), do: GenServer.call(__MODULE__, {:add, location})

  def init(_) do
    ensure_file_exists()
    {:ok, load_data()}
  end

  def handle_call(:list, _from, state), do: {:reply, state, state}

  def handle_call({:add, location}, _from, state) do
    new_state = state ++ [location]
    save_data(new_state)
    {:reply, :ok, new_state}
  end

  defp ensure_file_exists, do:
    unless File.exists?(@file), do: File.write!(@file, "[]")

  defp load_data do
    {:ok, content} = File.read(@file)
    Jason.decode!(content)
  rescue
    _ -> []
  end

  defp save_data(data),
    do: File.write!(@file, Jason.encode!(data, pretty: true))
end
