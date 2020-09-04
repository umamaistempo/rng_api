defmodule RngApi.UsersTest do
  use ExUnit.Case, async: true

  alias RngApi.Repo
  alias RngApi.Users
  alias RngApi.Users.User

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "find_users/2 using `:all` returns all entries" do
    Enum.each(1..100, fn _ -> Repo.insert!(User.create()) end)

    result = Users.find_users(:all)

    assert 100 == Enum.count(result)
  end

  test "find_users/2 using `{:point, :>=, value}` fetches only records with points bigger than or equal to value" do
    Enum.each(1..100, fn _ ->
      User.create()
      |> Ecto.Changeset.put_change(:points, 80)
      |> Repo.insert!()
    end)

    Enum.each(1..3, fn _ ->
      User.create()
      |> Ecto.Changeset.put_change(:points, 90)
      |> Repo.insert!()

      User.create()
      |> Ecto.Changeset.put_change(:points, 91)
      |> Repo.insert!()
    end)

    result = Users.find_users({:points, :>=, 90})

    # 3 with 90 points and 3 with 91 points
    assert 6 == Enum.count(result)
  end

  test "find_users/2 using `limit` limits results" do
    Enum.each(1..100, fn _ -> Repo.insert!(User.create()) end)

    result = Users.find_users(:all, limit: 3)

    assert 3 == Enum.count(result)
  end

  test "find_users/2 using `random` returns resultset randomly" do
    Enum.each(1..100, fn _ -> Repo.insert!(User.create()) end)

    result1 = Users.find_users(:all, [:random]) |> Enum.map(& &1.id)
    result2 = Users.find_users(:all, [:random]) |> Enum.map(& &1.id)

    refute result1 == result2
  end

  test "lazy_update/2 allows to dynamically update entries" do
    Enum.each(1..100, fn _ -> Repo.insert!(User.create()) end)

    result = Users.find_users({:points, :>=, 90})

    assert 0 == Enum.count(result)

    updater = fn user ->
      User.modify(user, %{points: 100})
    end

    Users.lazy_update({:all, []}, updater)

    result = Users.find_users({:points, :>=, 90})
    assert 100 == Enum.count(result)
  end
end
