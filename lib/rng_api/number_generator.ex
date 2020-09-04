defmodule RngApi.NumberGenerator do
  @spec start_link() :: GenServer.on_start()
  def start_link(),
    do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @spec run() :: {Time.t() | nil, [User.t()]}
  def run(),
    do: GenServer.call(__MODULE__, :run)

  @doc false
  def init(_) do
    timestamp = nil
    last_result = {nil, []}
    {max_number(), timestamp, last_result}
  end

  @doc false
  def handle_cast(:update, state = {max_number, _, _}) do
    update_users(max_number)
    {:noreply, state}
  end

  @doc false
  def handle_call(:run, _from, state = {max_number, timestamp, last_result}) do
    users = []

    new_result = {timestamp, users}

    {:reply, last_result, {max_number(), now(), new_result}}
  end

  defp max_number(),
    do: Enum.random(0..100)

  defp now(),
    do: Time.utc_now()
end
