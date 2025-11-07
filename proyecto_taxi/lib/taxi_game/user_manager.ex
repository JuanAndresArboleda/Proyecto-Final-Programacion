defmodule TaxiGame.UserManager do
  use GenServer

  @user_file "data/users.dat"

  ## ===== Public API =====
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def login_or_register(username, password) do
    users = load_users()

    case Map.get(users, username) do
      nil ->
        # Nuevo usuario, rol definido automáticamente
        role = ask_role(username)
        save_user(username, password, role, 0)
        {:ok, "Usuario #{username} registrado como #{role}"}

      %{password: ^password} ->
        {:ok, "Login exitoso como #{users[username].role}"}

      _ ->
        {:error, "Contraseña incorrecta"}
    end
  end

  def get_user(username) do
    load_users()[username]
  end

  def update_points(username, points) do
    users = load_users()

    case users[username] do
      nil -> {:error, "Usuario no existe"}
      user ->
        new_score = user.points + points
        save_user(username, user.password, user.role, new_score)
        {:ok, new_score}
    end
  end

  def leaderboard() do
    load_users()
    |> Map.values()
    |> Enum.sort_by(& &1.points, :desc)
    |> Enum.take(10)
  end

  ## ===== GEN SERVER =====
  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  ## ===== Internal File Logic =====

  defp load_users do
    File.mkdir_p!("data")

    if !File.exists?(@user_file), do: File.write!(@user_file, "")

    @user_file
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [u, p, r, pts] = String.split(line, "|")
      {u, %{password: p, role: r, points: String.to_integer(pts)}}
    end)
    |> Enum.into(%{})
  end

  defp save_user(username, password, role, points) do
    users = load_users() |> Map.put(username, %{password: password, role: role, points: points})

    users
    |> Enum.map(fn {u, data} ->
      "#{u}|#{data.password}|#{data.role}|#{data.points}"
    end)
    |> Enum.join("\n")
    |> then(&File.write!(@user_file, &1))
  end

  defp ask_role(username) do
    # default role logic
    if String.contains?(username, "driver"), do: "conductor", else: "cliente"
  end
end
