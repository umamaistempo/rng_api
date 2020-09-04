defmodule RngApi.Users.User do
  use Ecto.Schema
  alias Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :id, autogenerate: true}

  schema "users" do
    field :points, :integer, default: 0

    timestamps()
  end

  @spec create() :: Changeset.t(t)
  @doc """
  Creates a new user.
  """
  def create() do
    %__MODULE__{}
    |> Changeset.change()
  end

  @spec modify(t | Changeset.t(t), map) :: Changeset.t(t)
  @doc """
  Modifies an existing user.

  Allowed fields:

    - `points`
    - - **Required**. Must be an integer between 0 and 100
  """
  def modify(user, attrs) do
    user
    |> Changeset.cast(attrs, [:points])
    |> Changeset.validate_number(:points, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> Changeset.validate_required([:points])
  end
end
