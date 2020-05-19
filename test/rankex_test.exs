defmodule RankexTest do
  use ExUnit.Case
  doctest Rankex

  @massive             1_000_000
  @massive_insert         10_000
  @massive_update         10_000
  @massive_delete         10_000
  @assert_sample_size      1_000
  @timed_sample_size         100
  @min_sample_size           100

  test "insert/3 and all_with/1" do
    Rankex.init()
    id1 = random_id()
    score1 = random_score()

    # assert empty
    assert [] == Rankex.all_with(score1)

    # assert positive 1
    Rankex.insert(id1, score1, "name#{id1}")
    assert [id1] == Rankex.all_with(score1)

    # assert unchanged
    id2 = id1 + 1
    score2 = score1 + 1
    Rankex.insert(id2, score2, "name#{id2}")
    assert [id1] == Rankex.all_with(score1)

    # assert positive 2
    id3 = id1 + 1
    Rankex.insert(id3, score1, "name#{id3}")
    assert [id1, id3] == Rankex.all_with(score1)
  end

  test "insert_all/1 and top/1" do
    Rankex.init()

    %{id_score_list: id_score_list} = fixture(@min_sample_size)

    # assert empty
    assert 0 == Rankex.size()
    top = Rankex.top(@min_sample_size)
    assert [] == top

    records = for {id, score} <- id_score_list, do: {{score, id}, "name#{id}"}
    Rankex.insert_many(records)

    # assert inserted with top
    top = Rankex.top(length(records))
    assert is_list(top)
    assert top == Enum.sort_by(records, &(elem(&1, 0)), :desc)

    # assert top half
    half_length = div(length(records), 2)
    top = Rankex.top(half_length)
    first_half =
      records
      |> Enum.sort_by(&(elem(&1, 0)), :desc)
      |> Enum.take(half_length)

    assert is_list(top)
    assert top == first_half
  end

  test "insert/3, position_in/2 and position_by_id/1" do
    Rankex.init()
    %{
      id_score_list: id_score_list,
      score_pos_map: score_pos_map,
      id_pos_map: id_pos_map
    } = fixture(@min_sample_size)

    # empty
    assert 0 == Rankex.size()
    # insert each
    Enum.each(id_score_list, fn {id, score} -> Rankex.insert(id, score, "name#{id}") end)
    # tests each
    Enum.each(id_score_list,
      fn {id, score} ->
        position1 = Rankex.position_in(score, @min_sample_size)
        position2 = Rankex.position_by_id(id)

        # assert position1 == position2
        assert Enum.any?(Map.get(score_pos_map, score), fn pos -> pos == position1 end)
        if Map.get(id_pos_map, id) == position2 do
          assert Enum.any?(Rankex.all_with(score), &(&1 == id))
        end
      end)
  end

  test "[float score] insert/3, position_in/2 and position_by_id/1" do
    Rankex.init()
    id1 = random_id()
    score1 = 100.0001
    id2 = random_id()
    score2 = 100.0500

    assert nil == Rankex.position_by_id(id1)
    assert nil == Rankex.position_by_id(id2)
    Rankex.insert(id1, score1, "name#{id1}")
    Rankex.insert(id2, score2, "name#{id2}")
    assert 2 == Rankex.position_in(score1, 10)
    assert 1 == Rankex.position_in(score2, 10)
    assert 2 == Rankex.position_by_id(id1)
    assert 1 == Rankex.position_by_id(id2)
  end

  test "update/4, position_in/2 and position_by_id/1" do
    Rankex.init()
    id1 = random_id()
    id2 = random_id()
    id3 = random_id()
    score1 = random_score()
    score2 = score1 + 1
    score3 = score1 - 1

    assert nil == Rankex.position_by_id(id1)
    assert nil == Rankex.position_by_id(id2)
    assert nil == Rankex.position_by_id(id3)
    Rankex.insert(id1, score1, "name#{id1}")
    Rankex.insert(id2, score2, "name#{id2}")
    Rankex.insert(id3, score3, "name#{id3}")
    assert 2 == Rankex.position_in(score1, 10)
    assert 1 == Rankex.position_in(score2, 10)
    assert 3 == Rankex.position_in(score3, 10)
    assert 2 == Rankex.position_by_id(id1)
    assert 1 == Rankex.position_by_id(id2)
    assert 3 == Rankex.position_by_id(id3)

    Rankex.update(id3, score3, score2+1, "name#{id3}")
    score3 = score2+1
    assert 3 == Rankex.position_in(score1, 10)
    assert 2 == Rankex.position_in(score2, 10)
    assert 1 == Rankex.position_in(score3, 10)
    assert 3 == Rankex.position_by_id(id1)
    assert 2 == Rankex.position_by_id(id2)
    assert 1 == Rankex.position_by_id(id3)
  end

  test "leader/0" do
    Rankex.init()
    %{id_score_list: id_score_list, sorted_list: sorted_list} = fixture(@min_sample_size)

    for {id, score} <- id_score_list, do: {{score, id}, "name#{id}"}
    |> Rankex.insert_many()

    {leader_id, leader_score} = hd(sorted_list)
    assert Rankex.leader().id == leader_id
    assert Rankex.leader().score == leader_score
  end

  test "delete/2 and position_by_id/1" do
    Rankex.init()
    id1 = random_id()
    score = random_score()

    Rankex.insert(id1, score, "name#{id1}")
    assert 1 == Rankex.position_by_id(id1)
    Rankex.delete(id1, score)
    assert nil == Rankex.position_by_id(id1)
  end

  test "[float score] top/1 (:tuples)" do
    Rankex.init()
    id1 = random_id()
    id2 = random_id()
    score1 = random_score() / 100
    score2 = score1 + 0.0001
    detail1 = "name#{id1}"
    detail2 = "name#{id2}"

    Rankex.insert(id1, score1, detail1)
    assert Rankex.top(5) == [{{score1, id1}, detail1}]
    Rankex.insert(id2, score2, detail2)
    assert Rankex.top(5) == [{{score2, id2}, detail2}, {{score1, id1}, detail1}]

    Rankex.delete(id2, score2)
    assert Rankex.top(5) == [{{score1, id1}, detail1}]
  end

  test "top/1 (:tuples)" do
    Rankex.init()
    id1 = random_id()
    id2 = random_id()
    score1 = random_score()
    score2 = score1 + 1
    detail1 = "name#{id1}"
    detail2 = "name#{id2}"

    Rankex.insert(id1, score1, detail1)
    assert Rankex.top(5) == [{{score1, id1}, detail1}]
    Rankex.insert(id2, score2, detail2)
    assert Rankex.top(5) == [{{score2, id2}, detail2}, {{score1, id1}, detail1}]

    Rankex.delete(id2, score2)
    assert Rankex.top(5) == [{{score1, id1}, detail1}]
  end

  test "top/2 (:map_list)" do
    Rankex.init()
    id1 = random_id()
    id2 = random_id()
    score1 = random_score()
    score2 = score1 + 1
    detail1 = "name#{id1}"
    detail2 = "name#{id2}"

    Rankex.insert(id1, score1, detail1)
    ranking = Rankex.top(5, :map_list)
    first = hd(ranking)

    assert length(ranking) == 1
    assert first.id == id1
    assert first.score == score1
    assert first.detail == detail1

    Rankex.insert(id2, score2, detail2)
    ranking = Rankex.top(5, :map_list)
    [first, second | _] = ranking

    assert length(ranking) == 2
    assert first.id == id2
    assert first.score == score2
    assert first.detail == detail2
    assert second.id == id1
    assert second.score == score1
    assert second.detail == detail1

    Rankex.delete(id2, score2)
    ranking = Rankex.top(5, :map_list)
    first = hd(ranking)

    assert length(ranking) == 1
    assert first.id == id1
    assert first.score == score1
    assert first.detail == detail1
  end

  test "top/2 (:position_map)" do
    Rankex.init()
    id1 = random_id()
    id2 = random_id()
    score1 = random_score()
    score2 = score1 + 1
    detail1 = "name#{id1}"
    detail2 = "name#{id2}"

    Rankex.insert(id1, score1, detail1)
    ranking = Rankex.top(5, :position_map)

    assert is_map(ranking)
    assert nil != Map.get(ranking, 1)
    first = Map.get(ranking, 1)
    assert first.id == id1
    assert first.score == score1
    assert first.detail == detail1

    Rankex.insert(id2, score2, detail2)
    ranking = Rankex.top(5, :position_map)
    assert is_map(ranking)
    assert nil != Map.get(ranking, 1)
    assert nil != Map.get(ranking, 2)
    first = Map.get(ranking, 1)
    second = Map.get(ranking, 2)

    assert first.score == score2
    assert first.detail == detail2
    assert second.id == id1
    assert second.score == score1
    assert second.detail == detail1

    Rankex.delete(id2, score2)
    ranking = Rankex.top(5, :position_map)

    assert nil != Map.get(ranking, 1)
    first = Map.get(ranking, 1)
    assert first.id == id1
    assert first.score == score1
    assert first.detail == detail1
  end

  test "top/2 (:score_position_map)" do
    Rankex.init()
    id1 = random_id()
    id2 = random_id()
    score1 = random_score()
    score2 = score1 + 1
    detail1 = "name#{id1}"
    detail2 = "name#{id2}"

    Rankex.insert(id1, score1, detail1)
    ranking = Rankex.top(5, :score_position_map)
    assert is_map(ranking)

    first = Map.get(ranking, score1)
    assert not is_nil(first)
    assert first.id == id1
    assert first.position == 1
    assert first.detail == detail1

    Rankex.insert(id2, score2, detail2)
    ranking = Rankex.top(5, :score_position_map)
    assert is_map(ranking)

    first = Map.get(ranking, score2)
    second = Map.get(ranking, score1)
    assert not is_nil(first)
    assert not is_nil(second)
    assert first.id == id2
    assert first.position == 1
    assert first.detail == detail2
    assert second.id == id1
    assert second.position == 2
    assert second.detail == detail1

    Rankex.delete(id2, score2)
    ranking = Rankex.top(5, :score_position_map)
    assert is_map(ranking)

    first = Map.get(ranking, score1)
    assert not is_nil(first)
    assert first.id == id1
    assert first.position == 1
    assert first.detail == detail1
  end

  test "timed massive insert/3 for #{@massive_insert} items" do
    Rankex.init()
    t0 = NaiveDateTime.utc_now
    _scores = insert_random_scores(@massive_insert)
    t1 = NaiveDateTime.utc_now

    duration = NaiveDateTime.diff(t1, t0, :millisecond)

    IO.inspect "insert/3 for #{@massive_insert} items: #{duration}ms"
    assert duration < 1000
  end

  test "timed massive position_in/2 for #{@timed_sample_size} items" do
    Rankex.init()
    duration = positions_profiling(@timed_sample_size)
    IO.inspect "position_in/2 for #{@timed_sample_size} items: #{duration}ms"
    assert duration < 1000
  end

  test "timed massive update/3 (1mi)" do
    Rankex.init()
    scores = insert_random_scores(@massive_update)
    t0 = NaiveDateTime.utc_now
    Enum.each(scores,
      fn {score, id} ->
        Rankex.update(id, score, score+Enum.random(1..100000), "name#{id}")
      end)
    t1 = NaiveDateTime.utc_now

    duration = NaiveDateTime.diff(t1, t0, :millisecond)

    IO.inspect "update/4 for #{@massive_update} items: #{duration}ms"
    assert duration < 1000
  end

  test "timed massive delete/2 (1mi)" do
    Rankex.init()
    scores = insert_random_scores(@massive_delete)
    t0 = NaiveDateTime.utc_now
    Enum.each(scores,
      fn {score, id} ->
        Rankex.delete(id, score)
      end)
    t1 = NaiveDateTime.utc_now
    assert [] == Rankex.top(10)

    duration = NaiveDateTime.diff(t1, t0, :millisecond)

    IO.inspect "delete/2 for #{@massive_delete} items: #{duration}ms"
    assert duration < 1000
  end

  test "massive insert/3 (1mi) and position_in/2 for #{@assert_sample_size} items" do
    Rankex.init()
    duration = positions_profiling(@assert_sample_size, true)
    IO.inspect "position_in/1 for #{@assert_sample_size} items: #{duration}ms"
  end

  #
  # Internal
  #
  defp random_id, do: Enum.random(10_000_000_000_000_000..99_999_999_999_999_999)
  defp random_score(size \\ :normal)
  defp random_score(:normal), do: Enum.random(-100_000_000..100_000_000)
  defp random_score(:small), do: Enum.random(-10..10)

  defp fixture(size) do
    score_range = if size < 1000, do: :small, else: :normal
    id_score_list = for _i <- 1..size, do: {random_id(), random_score(score_range)}
    sorted_list = Enum.sort(id_score_list,
      fn {id1, score1}, {id2, score2} ->
        score1 > score2 or (score1 == score2 and id1 > id2)
      end)

    score_pos_map =
      sorted_list
      |> Enum.with_index(1)
      |> Enum.reduce(Map.new(),
          fn {{_id, score}, pos}, acc ->
            Map.update(acc, score, [pos], fn current_list -> current_list ++ [pos] end)
          end)

    id_pos_map =
      sorted_list
      |> Enum.with_index(1)
      |> Enum.into(Map.new(), fn {{id, _score}, pos} -> {id, pos} end)

    %{
      id_score_list: id_score_list,
      id_pos_map: id_pos_map,
      score_pos_map: score_pos_map,
      sorted_list: sorted_list
    }
  end

  defp insert_random_scores(amount) do
    for _i <- 1..amount do
      id = random_id()
      score = random_score()
      Rankex.insert(id, score, "name#{id}")
      {score, id}
    end
  end

  defp positions_profiling(sample_size, do_assert? \\ false) do
    topN =
      insert_random_scores(@massive)
      |> Enum.sort_by(&(elem(&1, 0)), :desc)
      |> Enum.take(sample_size)

    t0 = NaiveDateTime.utc_now

    Enum.reduce(topN, 1,
      fn {score, id}, position ->
        if do_assert? do
          if position != Rankex.position_in(score, sample_size) do
            same_score_ids = Rankex.all_with(score)
            assert Enum.any?(same_score_ids, fn id_table -> id_table == id end)
          end
        else
          Rankex.position_in(score, sample_size)
        end
      end)

    t1 = NaiveDateTime.utc_now

    NaiveDateTime.diff(t1, t0, :millisecond)
  end
end
