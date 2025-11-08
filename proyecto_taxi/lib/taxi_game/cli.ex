defmodule TaxiGame.CLI do
  @moduledoc """
  Interfaz de línea de comandos (CLI) para TaxiGame.
  """

  def start do
    IO.puts("\nBienvenido a TaxiGame\n")
    main_menu()
  end

  # Menú principal
  defp main_menu do
    IO.puts("""
    Selecciona una opción:
    1. Registrar usuario
    2. Ver usuarios
    3. Agregar ubicación
    4. Ver ubicaciones
    5. Crear viaje
    6. Ver viajes
    7. Asignar conductor a viaje
    8. Salir
    9. Marcar viaje como completado
    """)

    case IO.gets("> ") |> String.trim() do
      "1" -> register_user()
      "2" -> show_users()
      "3" -> add_location()
      "4" -> show_locations()
      "5" -> create_trip()
      "6" -> show_trips()
      "7" -> assign_driver()
      "8" ->
        IO.puts("¡Hasta luego!")
        :ok
      "9" -> complete_trip()
      _ ->
        IO.puts("Opción inválida.\n")
        main_menu()
    end
  end

  # Opciones del menú
  defp register_user do
    username = IO.gets("Nombre de usuario: ") |> String.trim()
    role = IO.gets("Rol (driver/passenger/admin): ") |> String.trim()

    TaxiGame.UserManager.add_user(username, %{role: role})
    IO.puts("Usuario #{username} registrado.\n")
    main_menu()
  end

  defp show_users do
    IO.puts("\n👥 Usuarios registrados:")
    IO.inspect(TaxiGame.UserManager.list_users())
    IO.puts("")
    main_menu()
  end

  defp add_location do
    name = IO.gets("Nombre de la ubicación: ") |> String.trim()
    x = IO.gets("Coordenada X: ") |> String.trim() |> String.to_integer()
    y = IO.gets("Coordenada Y: ") |> String.trim() |> String.to_integer()

    TaxiGame.Location.add_location(%{name: name, x: x, y: y})
    IO.puts("Ubicación #{name} agregada.\n")
    main_menu()
  end

  defp show_locations do
    IO.puts("\nUbicaciones registradas:")
    IO.inspect(TaxiGame.Location.list_locations())
    IO.puts("")
    main_menu()
  end

  defp create_trip do
    user = IO.gets("Usuario pasajero: ") |> String.trim()
    origin = IO.gets("Origen: ") |> String.trim()
    destination = IO.gets("Destino: ") |> String.trim()

    case TaxiGame.Trip.create(user, origin, destination) do
      {:ok, id} ->
        IO.puts("Viaje creado con ID #{id}.\n")
      {:error, :duplicate_trip} ->
        IO.puts("Error: ya existe un viaje activo con el mismo origen y destino.\n")
    end

    main_menu()
  end

  defp show_trips do
    IO.puts("\nViajes registrados:")
    trips = TaxiGame.Trip.list_trips()
    Enum.each(trips, fn t ->
      IO.puts("ID: #{t.id} | Usuario: #{t.user} | Origen: #{t.origin} | Destino: #{t.destination} | Conductor: #{t.driver || "No asignado"} | Estado: #{t.status} | Duración: #{t.duration || "-"}")
    end)
    IO.puts("")
    main_menu()
  end

  defp assign_driver do
    id = IO.gets("ID del viaje: ") |> String.trim() |> String.to_integer()
    driver = IO.gets("Nombre del conductor: ") |> String.trim()

    case TaxiGame.Trip.assign_driver(id, driver) do
      :ok ->
        IO.puts("Conductor asignado correctamente.\n")
      _ ->
        IO.puts("Error al asignar conductor. Revisa el ID del viaje.\n")
    end

    main_menu()
  end

  defp complete_trip do
    id = IO.gets("ID del viaje a completar: ") |> String.trim() |> String.to_integer()

    case TaxiGame.Trip.complete_trip(id) do
      {:ok, duration} ->
        IO.puts("Viaje completado. Duración simulada: #{duration} minutos.\n")
      {:error, :no_driver} ->
        IO.puts("No se puede completar el viaje: aún no tiene conductor asignado.\n")
      {:error, :not_found} ->
        IO.puts("Viaje no encontrado. Revisa el ID ingresado.\n")
    end

    main_menu()
  end
end
