defmodule RngApi.Repo do
  use Ecto.Repo,
    otp_app: :rng_api,
    adapter: Ecto.Adapters.Postgres
end
