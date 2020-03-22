# RankEx

A ranking/leaderboard library for Elixir based on ETS.

It's leveraged on ETS ordered set once it can also order some kinds of records 
with a tuple as key.

This way all operations regarding sorting is given for granted within a bulletproof cache.

For performance reasons, the insert, update and delete operations require the previous score.

Supports:

  - Fast insertion
  - Fast update
  - Fast delete
  - Position by score (thousand reads in 300ms) or id 
  - Detail field that might be used for rank names or other info 
  - All with operation for tied score
  - Multiple tables
  - Top N results in different formats:
    - :tuples : [{{score, id}, detail}, ...]
    - :map_list : [%{id: id, detail: detail, score: score}, ...]
    - :position_map : %{1: %{id: id, detail: detail, score: score}, 2: ...}
    - :score_position_map : %{score: %{id: id, detail: detail, position: position}, 2: ...}
  
# Benchmarking

"insert/3 for 10000 items: 30ms"

After inserting one million records:

 "delete/2 for 10000 items: 7ms"
 "update/4 for 10000 items: 37ms"
 "position_in/1 for 1000 items: 310ms"

Running on Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz and DDR4 2400 MT/s

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `benchmarking` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rankex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/benchmarking](https://hexdocs.pm/benchmarking).

