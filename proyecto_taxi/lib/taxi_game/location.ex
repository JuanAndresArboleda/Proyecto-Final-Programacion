defmodule TaxiGame.Location do
  use GenServer

  @file "data/locations.json"

  # API
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
  def list_locations, do: GenServer.call(__MODULE__, :list)
  def add_location(location), do: GenServer.call(__MODULE__, {:add, location})

  # Callbacks
  def init(_) do
    File.mkdir_p!("data")
    {:ok, load_data()}
  end

  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add, location}, _from, state) do
    new_state = state ++ [location]
    save_data(new_state)
    {:reply, :ok, new_state}
  end

  # File operations
  defp load_data do
    unless File.exists?(@file), do: File.write!(@file, "[]")

    case File.read(@file) do
      {:ok, content} when content != "" ->
        Jason.decode!(content)

      _ ->
        []
    end
  end

  defp save_data(data) do
    File.write!(@file, Jason.encode!(data, pretty: true))
  end
end
