defmodule TaxiGame.UserManager do
  use GenServer

  @file "data/users.json"

  def start_link(_opts),
    do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def register(username, password),
    do: GenServer.call(__MODULE__, {:register, username, password})

  def login(username, password),
    do: GenServer.call(__MODULE__, {:login, username, password})

  def login_or_register(username, password) do
    case login(username, password) do
      :ok -> {:ok, :logged_in}
      {:error, :not_found} ->
        case register(username, password) do
          :ok -> {:ok, :registered}
          error -> error
        end
      error -> error
    end
  end

  def init(_) do
    ensure_file_exists()
    {:ok, load_data()}
  end

  def handle_call({:register, username, password}, _from, users) do
    if Map.has_key?(users, username) do
      {:reply, {:error, :user_exists}, users}
    else
      updated = Map.put(users, username, %{password: password})
      save_data(updated)
      {:reply, :ok, updated}
    end
  end

  def handle_call({:login, username, password}, _from, users) do
    case Map.get(users, username) do
      nil -> {:reply, {:error, :not_found}, users}
      %{password: ^password} -> {:reply, :ok, users}
      _ -> {:reply, {:error, :invalid_password}, users}
    end
  end

  defp ensure_file_exists, do:
    unless File.exists?(@file), do: File.write!(@file, "{}")

  defp load_data do
    {:ok, content} = File.read(@file)
    Jason.decode!(content)
  rescue
    _ -> %{}
  end

  defp save_data(data),
    do: File.write!(@file, Jason.encode!(data, pretty: true))
end
