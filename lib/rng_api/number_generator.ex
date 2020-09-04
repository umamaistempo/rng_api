defmodule RngApi.NumberGenerator do
  use GenServer

  alias RngApi.Users
  alias RngApi.Users.User

  @spec start_link(any) :: GenServer.on_start()
  def start_link(_),
    do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @spec run() :: {DateTime.t() | nil, [User.t()]}
  def run(),
    do: GenServer.call(__MODULE__, :run)

  @doc false
  def init(_) do
    schedule_recurring_updates()

    timestamp = nil
    last_result = {nil, []}
    {:ok, {max_number(), timestamp, last_result}}
  end

  @doc false
  def handle_cast(:update, {_, timestamp, last_result}) do
    update_users()
    new_state = {max_number(), timestamp, last_result}
    {:noreply, new_state}
  end

  @doc false
  def handle_call(:run, _from, {max_number, timestamp, last_result}) do
    users = Users.find_users({:points, :>=, max_number}, [:random, limit: 2])

    new_result = {timestamp, users}

    {:reply, last_result, {max_number(), now(), new_result}}
  end

  defp max_number(),
    do: Enum.random(0..100)

  defp now(),
    do: DateTime.utc_now()

  defp schedule_recurring_updates(),
    do: :timer.apply_interval(60_000, GenServer, :cast, [self(), :update])

  defp update_users() do
    updater = fn user ->
      User.modify(user, %{points: Enum.random(0..100)})
    end

    # Updates every user on database one-by-one, setting their `points` attribute to a new random value
    Users.lazy_update({:all, []}, updater)
  end
end
