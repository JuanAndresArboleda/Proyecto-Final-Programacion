defmodule TaxiGame.UserManager do
  use GenServer

  @file "data/users.json"

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def login_or_register(username, password) do
    users = load_data()

    case Map.get(users, username) do
      nil ->
        role = if String.contains?(username, "driver"), do: "conductor", else: "cliente"
        new = Map.put(users, username, %{password: password, role: role, points: 0})
        save_data(new)
        {:ok, "Usuario #{username} registrado como #{role}"}

      %{password: ^password} ->
        {:ok, "Login exitoso como #{users[username].role}"}

      _ ->
        {:error, "Contraseña incorrecta"}
    end
  end

  def get_user(username), do: load_data()[username]

  def update_points(username, points) do
    users = load_data()

    case users[username] do
      nil -> {:error, "Usuario no existe"}
      user ->
        updated = Map.put(users, username, %{user | points: user.points + points})
        save_data(updated)
        {:ok, updated[username].points}
    end
  end

  def leaderboard do
    load_data()
    |> Map.values()
    |> Enum.sort_by(& &1.points, :desc)
    |> Enum.take(10)
  end

  # File utils
  defp load_data do
    unless File.exists?(@file), do: File.write!(@file, "{}")

    case File.read(@file) do
      {:ok, content} when content != "" -> Jason.decode!(content)
      _ -> %{}
    end
  end

  defp save_data(data) do
    File.write!(@file, Jason.encode!(data, pretty: true))
  end
end
