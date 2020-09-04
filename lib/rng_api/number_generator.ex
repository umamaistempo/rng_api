defmodule RngApi.NumberGenerator do
  use GenServer

  require Logger

  alias RngApi.Users
  alias RngApi.Users.User

  @type server_option ::
          {:cronjob, boolean}
          | {:name, GenServer.name()}
          | {:setup, (() -> any)}

  @spec start_link([server_option]) :: GenServer.on_start()
  def start_link(options) do
    server_name = Keyword.get(options, :name, __MODULE__)

    GenServer.start_link(__MODULE__, options, name: server_name)
  end

  @spec run() :: {DateTime.t() | nil, [User.t()]}
  def run(),
    do: GenServer.call(__MODULE__, :run)

  @doc false
  def init(options) do
    if Keyword.get(options, :cronjob, true) do
      schedule_recurring_updates()
    end

    # Callback for environment setup, like setting up initial seed for crypto, setting up a repository database etc
    setup = Keyword.get(options, :setup)

    if is_function(setup, 0) do
      setup.()
    end

    # As the `run/0` command returns the _last_ processed result, the first result has to be prepared beforehand;
    # this block effectively do that by generating the first "result" and progressing the timestamp.
    initial_timestamp = nil
    initial_max = max_number()
    state = result_helper(initial_max, initial_timestamp)

    {:ok, state}
  end

  @doc false
  def handle_cast(:update, {_, timestamp, last_result}) do
    Logger.info("Updating users point database")
    {:ok, updated_users} = update_users()
    Logger.info("Users updated: #{updated_users}")

    new_state = {max_number(), timestamp, last_result}
    {:noreply, new_state}
  end

  @doc false
  def handle_call(:run, _from, {max_number, timestamp, last_result}) do
    new_state = result_helper(max_number, timestamp)

    {:reply, last_result, new_state}
  end

  defp result_helper(initial_max, initial_timestamp) do
    result = {initial_timestamp, fetch_selected_random_users(initial_max)}

    new_max = max_number()
    new_timestamp = now()
    {new_max, new_timestamp, result}
  end

  defp max_number(),
    do: Enum.random(0..100)

  defp now(),
    do: DateTime.utc_now()

  # Uses erlang's timer to send a message to the RNG server every 60 seconds to get it to execute its update procedure.
  defp schedule_recurring_updates(),
    do: :timer.apply_interval(60_000, GenServer, :cast, [self(), :update])

  defp update_users() do
    updater = fn user ->
      User.modify(user, %{points: Enum.random(0..100)})
    end

    # Updates every user on database one-by-one, setting their `points` attribute to a new random value.
    # Note that this update is executed through several individual queries which is suboptimal but is the
    # easiest way to implement this feature while also keeping the business logic on the application side.
    # Alternatively, one could execute this procedure in up to 3 queries:
    # 1) Fetch all ids
    # 2) Execute an update query that maps id -> points
    # 3) Update all those entries with the same timestamp
    #
    # Alternatively the same could be done directly on the database on a single and efficient procedure, but that would take business logic into the database.
    Users.lazy_update({:all, []}, updater)
  end

  defp fetch_selected_random_users(max),
    do: Users.find_users({:points, :>=, max}, [:random, limit: 2])
end
