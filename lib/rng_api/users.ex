defmodule RngApi.Users do
  @moduledoc """
  A contextual interface for accessing `RngApi.Users` and its correlated resources
  """

  import Ecto.Query
  alias RngApi.Repo
  alias RngApi.Users.User

  @type find_query ::
          {:points, :>, integer}
          | :all

  @type find_option ::
          :random
          | {:limit, pos_integer}

  @spec find_users(find_query, [find_option]) :: [User.t()]
  @doc """
  Fetches records of `RngApi.Users.User`.

  `query` can be any of:
    - `{:points, :>, value}` where `value` is an integer. This will fetch users whose `points` is bigger than `value`.
    - `:all`. Fetches all users on database

  Additionally, the following `options` can be provided:
    - `random` - Will sort the resultset randomly.
    - `{:limit, value}` where `value` is an integer. Will limit the size of the resultset.
  """
  def find_users(query, options \\ []) do
    User
    |> users_query(query)
    |> users_query_options(options)
    |> Repo.all()
  end

  defp lazy_find_users(query, query_options, stream_options) do
    User
    |> users_query(query)
    |> users_query_options(query_options)
    |> Repo.stream(stream_options)
  end

  @spec lazy_update(
          {find_query, [find_option]},
          (User.t() -> Ecto.Changeset.t(User.t())),
          Keyword.t()
        ) :: {:ok, non_neg_integer} | {:error, any}
  @doc """
  Executes `update_fun` lazily on users filtered by `query` and `query_options` and updates each row individually.

  This operation is not optimized for frequent predictable runs.

  `query` and `query_options` parameters are the same from `find_users/2`.

  If the update operation fails for any reason, it will throw and the whole operation is cancelled.
  """
  def lazy_update({query, query_options}, update_fun, stream_options \\ [max_rows: 200]) do
    Repo.transaction(fn ->
      query
      |> lazy_find_users(query_options, stream_options)
      |> Enum.reduce(0, fn el, acc ->
        Repo.update!(update_fun.(el))
        acc + 1
      end)
    end)
  end

  defp users_query(query, :all),
    do: query

  defp users_query(query, {:points, :>, value}),
    do: where(query, [u], u.points > ^value)

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
