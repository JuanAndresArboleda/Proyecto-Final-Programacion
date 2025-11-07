defmodule Taxi.UserManager do
  use GenServer
  @users_file "data/users.dat"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    File.mkdir_p!("data")
    users = load_users()
    {:ok, users}
  end

  # API
  def authenticate_or_register(username, role, password) do
    GenServer.call(__MODULE__, {:auth_or_reg, username, role, password})
  end

  def add_score(username, delta) do
    GenServer.call(__MODULE__, {:add_score, username, delta})
  end

  def get_score(username) do
    GenServer.call(__MODULE__, {:get_score, username})
  end

  def ranking(limit \\ 10) do
    GenServer.call(__MODULE__, {:ranking, limit})
  end

  def handle_call({:auth_or_reg, username, role, password}, _from, users) do
    case Map.get(users, username) do
      nil ->
        user = %{username: username, role: role, password: password, score: 0}
        users2 = Map.put(users, username, user)
        persist_users(users2)
        {:reply, {:ok, user}, users2}

      %{password: ^password} = user ->
        {:reply, {:ok, user}, users}

      _ ->
        {:reply, {:error, :invalid_password}, users}
    end
  end

  def handle_call({:add_score, username, delta}, _from, users) do
    users2 =
      update_in(users, [username], fn
        nil -> nil
        u -> Map.update!(u, :score, &(&1 + delta))
      end)

    persist_users(users2)
    {:reply, :ok, users2}
  end

  def handle_call({:get_score, username}, _from, users) do
    score = users |> Map.get(username) |> (fn u -> if u, do: u.score, else: nil end).()
    {:reply, score, users}
  end

  def handle_call({:ranking, limit}, _from, users) do
    top =
      users
      |> Map.values()
      |> Enum.sort_by(& &1.score, :desc)
      |> Enum.take(limit)

    {:reply, top, users}
  end

  defp persist_users(users_map) do
    lines =
      users_map
      |> Map.values()
      |> Enum.map(fn u -> "#{u.username},#{u.role},#{u.password},#{u.score}\n" end)
      |> Enum.join()

    File.write!(@users_file, lines)
  end

  defp load_users do
    case File.read(@users_file) do
      {:ok, content} ->
        content
        |> String.split("\n", trim: true)
        |> Enum.reduce(%{}, fn line, acc ->
          case String.split(line, ",") do
            [username, role_s, password, score_s] ->
              role = String.to_atom(role_s)
              score = String.to_integer(score_s)
              Map.put(acc, username, %{username: username, role: role, password: password, score: score})

            _ -> acc
          end
        end)

      {:error, _} ->
        %{}
    end
  end
end
