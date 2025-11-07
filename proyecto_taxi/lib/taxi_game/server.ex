defmodule Taxi.Server do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{sessions: %{}, trips: MapSet.new()}, name: __MODULE__)
  end

  def init(state) do
    Registry.start_link(keys: :unique, name: Taxi.TripRegistry)
    {:ok, state}
  end

  def connect(caller, username, role_str, password) do
    role = parse_role(role_str)
    GenServer.call(__MODULE__, {:connect, caller, username, role, password})
  end

  def disconnect(caller) do
    GenServer.call(__MODULE__, {:disconnect, caller})
  end

  def request_trip(caller, username, origin, destination) do
    GenServer.call(__MODULE__, {:request_trip, caller, username, origin, destination})
  end

  def list_trips() do
    Registry.select(Taxi.TripRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.map(fn id ->
      case Taxi.Trip.list_info(id) do
        %{"state" => :waiting} -> Taxi.Trip.list_info(id)
        m when is_map(m) -> if m["state"] == :waiting, do: m, else: nil
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def accept_trip(_caller, trip_id, driver) do
    case Taxi.Trip.accept(trip_id, driver) do
      {:ok, _} ->
        {:ok, trip_id}

      {:error, _} = e ->
        e
    end
  end

  def my_score(username) do
    Taxi.UserManager.get_score(username)
  end

  def ranking() do
    Taxi.UserManager.ranking(20)
  end

  def handle_call({:connect, caller, username, role, password}, _from, state) do
    case Taxi.UserManager.authenticate_or_register(username, role, password) do
      {:ok, _user} ->
        sessions = Map.put(state.sessions, caller, username)
        {:reply, {:ok, username}, %{state | sessions: sessions}}

      {:error, :invalid_password} ->
        {:reply, {:error, :invalid_password}, state}
    end
  end

  def handle_call({:disconnect, caller}, _from, state) do
    sessions = Map.delete(state.sessions, caller)
    {:reply, :ok, %{state | sessions: sessions}}
  end

  def handle_call({:request_trip, _caller, username, origin, destination}, _from, state) do
    cond do
      not Taxi.Location.valid_location?(origin) ->
        {:reply, {:error, :invalid_origin}, state}

      not Taxi.Location.valid_location?(destination) ->
        {:reply, {:error, :invalid_destination}, state}

      true ->
        id = :erlang.unique_integer([:positive]) |> Integer.to_string()
        args = %{id: id, client: username, origin: origin, destination: destination}
        spec = {Taxi.Trip, args}
        case DynamicSupervisor.start_child(Taxi.TripSupervisor, spec) do
          {:ok, _pid} ->
            {:reply, {:ok, id}, %{state | trips: MapSet.put(state.trips, id)}}
          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  defp parse_role("client"), do: :client
  defp parse_role("cliente"), do: :client
  defp parse_role("driver"), do: :driver
  defp parse_role("conductor"), do: :driver
  defp parse_role(_), do: :client
end
