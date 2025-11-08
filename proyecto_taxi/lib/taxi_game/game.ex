defmodule TaxiGame.Game do
  @moduledoc """
  Módulo principal del simulador TaxiGame.
  Se encarga de iniciar los servicios y ejecutar flujos de ejemplo.
  """

  alias TaxiGame.{UserManager, Location, Trip}

  #Iniciar todos los servicios
  def start do
    IO.puts("Iniciando TaxiGame...")

    ensure_started(UserManager)
    ensure_started(Location)
    ensure_started(Trip)

    IO.puts("Todos los servicios iniciados correctamente.")
  end

  #Crear algunos datos de ejemplo
  def demo do
    IO.puts("\n Creando datos de ejemplo...")

    UserManager.add_user("Camilo", %{role: "passenger"})
    UserManager.add_user("Laura", %{role: "driver"})

    Location.add_location(%{name: "Centro"})
    Location.add_location(%{name: "Aeropuerto"})

    {:ok, trip_id} = Trip.create("Camilo", "Centro", "Aeropuerto")
    Trip.assign_driver(trip_id, "Laura")

    IO.puts("\n Estado actual del juego:")
    IO.inspect(UserManager.list_users(), label: "Usuarios")
    IO.inspect(Location.list_locations(), label: "Ubicaciones")
    IO.inspect(Trip.list_trips(), label: "Viajes")

    IO.puts("\n Simulación completada.")
  end

  #Función auxiliar
  defp ensure_started(module) do
    case Process.whereis(module) do
      nil ->
        {:ok, _pid} = module.start_link([])
      _ ->
        :ok
    end
  end
end
