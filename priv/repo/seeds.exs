# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     RngApi.Repo.insert!(%RngApi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Enum.reduce(1..100, fn _ ->
  user = RngApi.Users.User.create()
  RngApi.Repo.create!(user)
end)
