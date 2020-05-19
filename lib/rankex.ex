defmodule Rankex do
  @moduledoc """
  A ranking/leaderboard library for Elixir based on ETS.

  It's leveraged on ETS ordered set once it can also order some kinds of records
  with a tuple as key.

  This way all operations regarding sorting is given for granted within a bulletproof cache.

  For performance reasons, update and delete operations require the previous score which
  should be already stored in users cache.

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
      - :score_position_map : %{score_value => %{id: id, detail: detail, position: position}, ...}

  # Benchmarking

  insert/3 for 10000 items: 30ms

  After inserting one million records:

  delete/2 for 10000 items: 7ms
  update/4 for 10000 items: 37ms
  position_in/1 for 1000 items: 310ms

  Running on Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz and DDR4 2400 MT/s

  """
  @table :rankex_table
  @eot   :"$end_of_table"

  @doc """
  Creates default table.
  """
  def init() do
    init(@table)
  end
  @doc """
  Creates named table.
  """
  def init(table) do
    :ets.new(table, [:ordered_set, :named_table, :public])
  end

  @doc """
  All items with certain score.
  """
  def all_with(score) do
    all_with(@table, score)
  end
  @doc """
  All items with certain score (in a named table).
  """
  def all_with(table, score) do
    :ets.match_object(table, {{score, :_}, :_})
    |> Enum.map(fn {{_score, id}, _detail} -> id end)
  end

  @doc """
  Deletes item from ranking.
  """
  def delete(id, prev_stored_score) do
    delete(@table, id, prev_stored_score)
  end
  @doc """
  Deletes item from ranking (of named table).
  """
  def delete(table, id, prev_stored_score) do
    :ets.delete(table, {prev_stored_score, id})
  end

  @doc """
  Inserts and sorts item on ranking.

  Params:
  id: integer, UUID, etc.
  new_score: integer or float
  detail: might be the name of a person on the raking or any other detail related to the id.
  """
  def insert(id, new_score, detail) do
    insert(@table, id, new_score, detail)
  end
  @doc """
  Inserts and sorts item on ranking (of named table).
  """
  def insert(table, id, new_score, detail) do
    :ets.insert(table, {{new_score, id}, detail})
  end

  @doc """
  Inserts and sorts many item on ranking.

  Params:
  list: [{{score, id}, detail}, ...]
  """
  def insert_many(record_list) do
    insert_many(@table, record_list)
  end
  @doc """
  Inserts and sorts item on ranking (of named table).
  """
  def insert_many(table, record_list) do
    :ets.insert(table, record_list)
  end

  @doc """
  Returns a map with leader data or nil.
  """
  def leader() do
    leader(@table)
  end
  @doc """
  Returns a map with leader data or nil (of named table).
  """
  def leader(table) do
    record = :ets.last(table)
    if record != @eot do
      {score, id} = record
      %{
        id: id,
        score: score,
      }
    end
  end

  @doc """
  Updates score and position of an item on ranking.
  """
  def update(id, prev_stored_score, new_score, detail) do
    update(@table, id, prev_stored_score, new_score, detail)
  end
  @doc """
  Updates score and position of an item on ranking (of named table).
  """
  def update(table, id, prev_stored_score, new_score, detail) do
    :ets.delete(table, {prev_stored_score, id})
    :ets.insert(table, {{new_score, id}, detail})
  end

  @doc """
  Gives the position/rank for an item with given score.
  """
  def position_in(score, rank_size) do
    position_in(@table, score, rank_size)
  end
  @doc """
  Gives the position/rank for an item with given score (in named table).
  """
  def position_in(table, score, rank_size) do
    top(table, rank_size, :score_position_map)
    |> Map.get(score)
    |> Map.get(:position)
  end

  @doc """
  Gives the position/rank for an item with given id.

  This is much slower than position/1 once the table is sorted by score.
  """
  def position_by_id(id) do
    position_by_id(@table, id)
  end
  @doc """
  Gives the position/rank for an item with given id (in named table).

  This is much slower than position/2 once the table is sorted by score.
  """
  def position_by_id(table, id) do
    match_list = :ets.match_object(table, {{:_, id}, :_})
    if [] != match_list do
      {{score, _id}, _detail} = hd(match_list)
      count_ms = [{
        {{:"$1", :_}, :_},
        [{:>, :"$1", {:const, score}}],
        [true]
      }]
      1 + :ets.select_count(table, count_ms)
    end
  end

  @doc """
  Number of items in the ranking.
  """
  def size() do
    size(@table)
  end
  @doc """
  Number of items in the ranking (of named table).
  """
  def size(table) do
    :ets.info(table, :size)
  end
  @doc """
  Returns the top N items of the ranking.

  format for the modes:
  :tuples : [{{score, id}, detail}, ...]
  :map_list : [%{id: id, detail: detail, score: score}, ...]
  :position_map : %{1: %{id: id, detail: detail, score: score}, 2: ...}
  :score_position_map : %{score: %{id: id, detail: detail, position: position}, 2: ...}
  """
  def top(num, mode \\ :tuples) do
    top(@table, num, mode)
  end
  @doc """
  Returns the top N items of the ranking (for a named table).
  """
  def top(table, num, mode) do
    :ets.select_reverse(table, [{:_, [], [:'$_']}], num)
    |> format_result(mode)
  end

  #
  # Internal
  #
  defp format_result(@eot, _mode), do: []
  defp format_result({records, _cont}, :tuples), do: records
  defp format_result({records, _cont}, :map_list) do
    Enum.map(records,
      fn {{score, id}, detail} ->
        %{
          id: id,
          detail: detail,
          score: score
        }
      end)
  end
  defp format_result({records, _cont}, :position_map) do
    Enum.reduce(records, {1, %{}},
      fn {{score, id}, detail}, {position, acc} ->
        new_acc =
          Map.put(acc, position,
            %{
              id: id,
              detail: detail,
              score: score
            })
        {position+1, new_acc}
      end)
    |> elem(1)
  end
  defp format_result({records, _cont}, :score_position_map) do
    Enum.reduce(records, {1, %{}},
      fn {{score, id}, detail}, {position, acc} ->
        new_acc =
          Map.put(acc, score,
            %{
              id: id,
              detail: detail,
              position: position
            })
        {position+1, new_acc}
      end)
    |> elem(1)
  end
end
