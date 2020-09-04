defmodule RngApi.Users do
  @moduledoc """
  A contextual interface for accessing `RngApi.Users` and its correlated resources
  """

  import Ecto.Query
  alias RngApi.Repo
  alias RngApi.Users.User

  @type find_query ::
          {:points, :>=, integer}

  @type find_option ::
          :random
          | {:limit, pos_integer}

  @spec find_users(find_query, [find_option]) :: [User.t()]
  @doc """
  Fetches records of `RngApi.Users.User`.

  `query` can be any of:
    - `{:points, :>=, value}` where `value` is an integer. This will fetch users whose `points` is bigger than or equals to `value`.

  Additionally, the following `options` can be provided:
    - `random` - Will sort the resultset randomly.
    - `{:limit, value}` where `value` is an integer. Will limit the size of the resultset.
  """
  def find_users(query, options) do
    User
    |> users_query(query)
    |> users_query_options(options)
    |> Repo.all()
  end

  defp users_query(query, {:points, :>=, value}),
    do: where(query, [u], u.points >= ^value)

  defp users_query_options(query, [:random | options]) do
    query
    |> order_by(fragment("RANDOM()"))
    |> users_query_options(options)
  end

  defp users_query_options(query, [{:limit, value} | options]) do
    query
    |> limit(^value)
    |> users_query_options(options)
  end

  defp users_query_options(query, []) do
    query
  end
end
