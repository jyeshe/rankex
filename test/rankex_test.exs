defmodule RankexTest do
  use ExUnit.Case
  doctest Rankex

  @massive             1_000_000
  @massive_insert         10_000
  @massive_update         10_000
  @massive_delete         10_000
  @timed_sample_size       1_000
  @assert_sample_size      5_000

  test "insert/3 and all_with/1" do
    Rankex.init()
    id = random_id()
    score = random_score()

    assert [] == Rankex.all_with(score)
    Rankex.insert(id, score, "name#{id}")
    assert [id] == Rankex.all_with(score)
  end

  test "insert/3, position/1 and position_by_id/1" do
    Rankex.init()
    id = random_id()
    score = random_score()

    assert nil == Rankex.position_by_id(id)
    Rankex.insert(id, score, "name#{id}")
    assert 1 == Rankex.position_in(score, 10)
    assert 1 == Rankex.position_by_id(id)
  end

  test "[float score] insert/3, position/1 and position_by_id/1" do
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

  test "update/4, position/1 and position_by_id/1" do
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

  test "timed massive position/1 for #{@timed_sample_size} items" do
    Rankex.init()
    duration = positions_profiling(@timed_sample_size)
    IO.inspect "position/1 for #{@timed_sample_size} items: #{duration}ms"
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

  test "massive insert/3 (1mi) and position/1 for #{@assert_sample_size} items" do
    Rankex.init()
    duration = positions_profiling(@assert_sample_size, true)
    IO.inspect "position/1 for #{@assert_sample_size} items: #{duration}ms"
  end

  #
  # Internal
  #
  defp random_id, do: Enum.random(1234567890123456..9876543210123456)
  defp random_score, do: Enum.random(-100_000_000..100_000_000)

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
