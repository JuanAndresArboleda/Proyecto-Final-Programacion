defmodule TaxiGame.Server do
  use GenServer
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def connect(username, password),
    do: GenServer.call(__MODULE__, {:connect, username, password})

  def request_trip(user, origin, destination),
    do: GenServer.call(__MODULE__, {:request_trip, user, origin, destination})

  def list_trips,
    do: GenServer.call(__MODULE__, :list_trips)

  def accept_trip(driver, trip_id),
    do: GenServer.call(__MODULE__, {:accept_trip, driver, trip_id})

  def init(state),
    do: {:ok, state}

  #Manejo de conexion
  def handle_call({:connect, username, password}, _from, state) do
    case TaxiGame.UserManager.login_or_register(username, password) do
      {:ok, user_info} ->
        IO.puts("\nBienvenido de nuevo, #{username} (rol: #{user_info.role})")
        {:reply, {:ok, user_info}, state}

      {:new_user, username} ->
        IO.puts("\nUsuario nuevo detectado: #{username}")
        role = ask_role()
        TaxiGame.UserManager.add_user(username, %{password: password, role: role})
        IO.puts("Usuario registrado como #{role}.")
        {:reply, {:ok, %{username: username, role: role}}, state}

      {:error, :invalid_password} ->
        IO.puts("\nContrasena incorrecta.")
        {:reply, {:error, :invalid_password}, state}
    end
  end

  #Manejo de viajes
  def handle_call({:request_trip, user, origin, destination}, _from, state) do
    {:reply, TaxiGame.Trip.create(user, origin, destination), state}
  end

  def handle_call(:list_trips, _from, state) do
    {:reply, TaxiGame.Trip.list_trips(), state}
  end

  def handle_call({:accept_trip, driver, trip_id}, _from, state) do
    {:reply, TaxiGame.Trip.assign_driver(trip_id, driver), state}
  end

  # Funcion auxiliar
  defp ask_role do
    IO.puts("\nElige tu rol:")
    IO.puts("1. Pasajero")
    IO.puts("2. Conductor")

    case IO.gets("Selecciona una opcion (1 o 2): ") |> String.trim() do
      "1" -> "passenger"
      "2" -> "driver"
      _ ->
        IO.puts("Opcion no valida, se asigna pasajero por defecto.")
        "passenger"
    end
  end
end
