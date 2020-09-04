# RngApi

This program is a simple API that returns semi-randomly up to 2 users whenever you hit the endpoint.

This API does so by running a query fetching up to 2 random users that have more than or equal to a secret random internal limit.

To ensure consistent high-quality semi-random values, an internal timer changes the users suitability to the algorithm every 60 sesconds.

Check `RngApi.NumberGenerator` for more insights on how the RNG selects which users to choose from.

## Under the table

The `RngApi.NumberGenerator` sets a random "minimum" that it uses as rejection criteria, after filtering out all users with less than or equal to that `minimum`, the resultset is limited to 2 randomly selected entries. This value is then cached at the RNG state and will be provided **on the next** request, including the timestamp of the current request.

This means that the first request to the RNG server will always have a `nil` timestamp (as the first resultset will be produced on startup).

After every request the "limit" will be randomly defined, which will improve entropy on the resultset.

Eg:

First request on 12:01:00
```
{
  "timestamp": null
}
```

Second request on 12:03:25
```
{
  "timestamp": "2020-09-04T12:01:00Z"
}
```

Third request on 12:04:05
```
{
  "timestamp": "2020-09-04T12:93:25Z"
}
```

## Running

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Every time you hit that endpoint, it will show the last time the endpoint was reached and two semi-random users
