defmodule RngApi.Users.UserTest do
  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias RngApi.Users.User

  test "create/0 returns a create-able changeset with default points" do
    changeset = User.create()

    assert {:ok, user} = Changeset.apply_action(changeset, :insert)
    assert 0 === user.points
  end

  test "modify/2 requires `points` to be present" do
    changeset =
      User.create()
      |> Changeset.apply_action!(:insert)
      |> User.modify(%{points: nil})

    refute changeset.valid?
    assert Keyword.has_key?(changeset.errors, :points)
  end

  test "modify/2 requires `points` to be bigger than or equal to 0" do
    changeset =
      User.create()
      |> Changeset.apply_action!(:insert)
      |> User.modify(%{points: 0})

    assert changeset.valid?

    changeset = User.modify(changeset, %{points: 1})
    assert changeset.valid?

    changeset = User.modify(changeset, %{points: -1})
    refute changeset.valid?
  end

  test "modify/2 requires `points` to be less than or equal to 100" do
    changeset =
      User.create()
      |> Changeset.apply_action!(:insert)
      |> User.modify(%{points: 100})

    assert changeset.valid?

    changeset = User.modify(changeset, %{points: 99})
    assert changeset.valid?

    changeset = User.modify(changeset, %{points: 101})
    refute changeset.valid?
  end
end
