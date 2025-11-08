defmodule TaxiGame.UserManager do
  use GenServer

  @file_path "data/users.json"

  # Public API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def add_user(name, info) do
    GenServer.call(__MODULE__, {:add_user, name, info})
  end

  def get_user(name) do
    GenServer.call(__MODULE__, {:get_user, name})
  end

  def list_users() do
    GenServer.call(__MODULE__, :list_users)
  end

  def login_or_register(username, password) do
    GenServer.call(__MODULE__, {:login_or_register, username, password})
  end

  # Callbacks
  def init(_state) do
    ensure_data_dir()
    users = load_from_file()
    {:ok, users}
  end

  def handle_call({:add_user, name, info}, _from, state) do
    new_state = Map.put(state, name, info)
    save_to_file(new_state)
    {:reply, :ok, new_state}
  end

  def handle_call({:get_user, name}, _from, state) do
    {:reply, Map.get(state, name), state}
  end

  def handle_call(:list_users, _from, state) do
    {:reply, state, state}
  end

  # Main login and register logic
  def handle_call({:login_or_register, username, password}, _from, state) do
    case Map.get(state, username) do
      nil ->
        # Register new user as passenger by default
        new_user = %{password: password, role: "passenger"}
        new_state = Map.put(state, username, new_user)
        save_to_file(new_state)
        {:reply, {:registered, username}, new_state}

      %{password: ^password} ->
        {:reply, {:ok, username}, state}

      _ ->
        {:reply, {:error, :invalid_password}, state}
    end
  end

  # JSON persistence
  defp load_from_file do
    ensure_data_dir()

    case File.read(@file_path) do
      {:ok, body} when body != "" ->
        case Jason.decode(body) do
          {:ok, data} -> data
          _ -> %{}
        end

      _ ->
        File.write!(@file_path, "{}")
        %{}
    end
  end

  defp save_to_file(data) do
    ensure_data_dir()
    json = Jason.encode!(data, pretty: true)
    File.write!(@file_path, json)
  end

  defp ensure_data_dir do
    File.mkdir_p!("data")
  end
end
