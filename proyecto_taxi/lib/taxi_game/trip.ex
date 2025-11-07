defmodule TaxiGame.Trip do
  use GenServer

  @duration 20_000  # 20 segundos

  ### PUBLIC API ###

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def create(user, origin, destination) do
    trip_id = :erlang.unique_integer([:positive]) |> Integer.to_string()
    args = %{id: trip_id, client: user, origin: origin, destination: destination}
    {:ok, _pid} = TaxiGame.TripSupervisor.start_trip(args)
    {:ok, trip_id}
  end

  def list_active() do
    # luego guardamos estados reales
    Process.list()
    |> Enum.filter(fn pid ->
      case Process.info(pid, :dictionary) do
        {:dictionary, dict} -> Keyword.get(dict, :"$initial_call") == {__MODULE__, :init, 1}
        _ -> false
      end
    end)
    |> Enum.map(& &1)
  end

  def assign_driver(trip_id, _driver) do
    # ahora la variable no usada está corregida
    {:ok, "driver assigned to trip #{trip_id}"}
  end

  ### CALLBACKS ###

  @impl true
  def init(args) do
    Process.send_after(self(), :finish, @duration)
    {:ok, Map.put(args, :driver, nil)}
  end

  @impl true
  def handle_info(:finish, state) do
    IO.puts("Trip #{state.id} completed")
    {:stop, :normal, state}
  end
end
