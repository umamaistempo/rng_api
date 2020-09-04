defmodule RngApi.NumberGeneratorTest do
  use ExUnit.Case, async: true

  alias RngApi.NumberGenerator
  alias RngApi.Repo
  alias RngApi.Users.User

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Enum.each(1..100, fn _ -> Repo.insert!(User.create()) end)

    restart_server()
    :ok
  end

  test "first call to `run/0` should return nil timestamp" do
    assert {nil, _} = run()
  end

  test "subsequent calls to `run/0` should return progressive timestamps" do
    {nil, _} = run()
    {t1, _} = run()
    {t2, _} = run()
    {t3, _} = run()
    {t4, _} = run()

    assert :gt == DateTime.compare(t2, t1)
    assert :gt == DateTime.compare(t3, t2)
    assert :gt == DateTime.compare(t4, t3)
  end

  test "`run/0` returns only users whose `points` value is bigger than the internal max" do
    Repo.delete_all(User)

    # The number generator should have a `max` between 0 and 100, so by having users with less than 0, they will never be fetched
    Enum.each(1..100, fn _ ->
      User.create()
      |> Ecto.Changeset.put_change(:points, -1)
      |> Repo.insert!()
    end)

    restart_server()

    assert {_, []} = run()
    assert {_, []} = run()
    assert {_, []} = run()
    assert {_, []} = run()
    assert {_, []} = run()
    assert {_, []} = run()
    assert {_, []} = run()
  end

  test "`run/0` returns up to 2 users whose `points` value is bigger than the internal max" do
    Repo.delete_all(User)

    # The number generator should have a `max` between 0 and 100, so by having users with less than 0, they will never be fetched
    Enum.each(1..100, fn _ ->
      User.create()
      |> Ecto.Changeset.put_change(:points, -1)
      |> Repo.insert!()
    end)

    # Those users have a `points` value bigger than the maximum possible value from the NumberGenerator server, so they
    # should always be possible selections for the server
    expected_ids =
      Enum.map(1..10, fn _ ->
        User.create()
        |> Ecto.Changeset.put_change(:points, 999)
        |> Repo.insert!()
        |> Map.fetch!(:id)
      end)

    restart_server()

    for _ <- 1..100 do
      {_, users} = run()

      assert Enum.count(users) in 0..2

      Enum.each(users, fn user ->
        assert user.id in expected_ids
      end)
    end
  end

  test "`run/0` returned users are random" do
    Repo.delete_all(User)

    # Those users have a `points` value bigger than the maximum possible value from the NumberGenerator server, so they
    # should always be possible selections for the server
    # Also note that the set of possible users is big enough to make it virtually impossible to have a randomic collision
    Enum.each(1..100, fn _ ->
      User.create()
      |> Ecto.Changeset.put_change(:points, 999)
      |> Repo.insert!()
    end)

    restart_server()

    {_, xs1} = run()
    {_, xs2} = run()
    {_, xs3} = run()

    assert xs1 != xs2 or xs2 != xs3
  end

  defp run(),
    do: GenServer.call(__MODULE__, :run)

  defp restart_server() do
    test_agent_pid = self()

    sandbox_setup = fn ->
      Ecto.Adapters.SQL.Sandbox.allow(Repo, test_agent_pid, self())
    end

    # Stops the local NumberGenerator if it is running, to return it to its initial state
    if GenServer.whereis(__MODULE__) do
      GenServer.stop(__MODULE__)
    end

    NumberGenerator.start_link(name: __MODULE__, cronjob: false, setup: sandbox_setup)
  end
end
