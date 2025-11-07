defmodule Taxi.Trip do
  use GenServer
  require Logger

  @trip_duration 20_000
  @accept_timeout 30_000

  defstruct [:id, :client, :origin, :destination, :driver, :state, :timer_ref]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: via_tuple(args.id))
  end

  def via_tuple(id), do: {:via, Registry, {Taxi.TripRegistry, id}}

  def init(%{id: id, client: client, origin: origin, destination: destination}) do
    state = %__MODULE__{
      id: id,
      client: client,
      origin: origin,
      destination: destination,
      driver: nil,
      state: :waiting,
      timer_ref: nil
    }

    ref = Process.send_after(self(), :expire, @accept_timeout)
    {:ok, %{state | timer_ref: ref}}
  end

  def list_info(id) do
    GenServer.call(via_tuple(id), :info)
  end

  def accept(id, driver) do
    GenServer.call(via_tuple(id), {:accept, driver})
  end

  def handle_call(:info, _from, s) do
    {:reply, Map.from_struct(s), s}
  end

  def handle_call({:accept, driver}, _from, s = %__MODULE__{state: :waiting}) do
    if s.timer_ref, do: Process.cancel_timer(s.timer_ref)
    ref = Process.send_after(self(), :finish, @trip_duration)
    s2 = %{s | driver: driver, state: :in_progress, timer_ref: ref}
    {:reply, {:ok, s2.id}, s2}
  end

  def handle_call({:accept, _driver}, _from, s) do
    {:reply, {:error, :not_available}, s}
  end

  def handle_info(:expire, s = %__MODULE__{state: :waiting}) do
    write_result("#{Date.utc_today()}; cliente=#{s.client}; conductor=none; origen=#{s.origin}; destino=#{s.destination}; status=Expirado\n")
    Taxi.UserManager.add_score(s.client, -5)
    {:stop, :normal, %{s | state: :expired}}
  end

  def handle_info(:finish, s = %__MODULE__{state: :in_progress, driver: driver}) do
    write_result("#{Date.utc_today()}; cliente=#{s.client}; conductor=#{driver}; origen=#{s.origin}; destino=#{s.destination}; status=Completado\n")
    Taxi.UserManager.add_score(s.client, 10)
    Taxi.UserManager.add_score(driver, 15)
    {:stop, :normal, %{s | state: :completed}}
  end

  defp write_result(line) do
    File.mkdir_p!("data")
    File.write!("data/results.log", line, [:append])
  end
end
