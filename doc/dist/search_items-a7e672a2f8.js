searchNodes=[{"doc":"A ranking/leaderboard library for Elixir based on ETS. It&#39;s leveraged on ETS ordered set once it can also order some kinds of records with a tuple as key. This way all operations regarding sorting is given for granted within a bulletproof cache. For performance reasons, update and delete operations require the previous score which should be already stored in users cache. Supports: Fast insertion Fast update Fast delete Position by score (thousand reads in 300ms) or id Detail field that might be used for rank names or other info All with operation for tied score Multiple tables Top N results in different formats: :tuples : [{{score, id}, detail}, ...] :map_list : [%{id: id, detail: detail, score: score}, ...] :position_map : %{1: %{id: id, detail: detail, score: score}, 2: ...} :score_position_map : %{score_value =&gt; %{id: id, detail: detail, position: position}, ...} Benchmarking insert/3 for 10000 items: 30ms After inserting one million records: delete/2 for 10000 items: 7ms update/4 for 10000 items: 37ms position_in/1 for 1000 items: 310ms Running on Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz and DDR4 2400 MT/s","ref":"Rankex.html","title":"Rankex","type":"module"},{"doc":"All items with certain score.","ref":"Rankex.html#all_with/1","title":"Rankex.all_with/1","type":"function"},{"doc":"All items with certain score (in a named table).","ref":"Rankex.html#all_with/2","title":"Rankex.all_with/2","type":"function"},{"doc":"Deletes item from ranking.","ref":"Rankex.html#delete/2","title":"Rankex.delete/2","type":"function"},{"doc":"Deletes item from ranking (of named table).","ref":"Rankex.html#delete/3","title":"Rankex.delete/3","type":"function"},{"doc":"Creates default table.","ref":"Rankex.html#init/0","title":"Rankex.init/0","type":"function"},{"doc":"Creates named table.","ref":"Rankex.html#init/1","title":"Rankex.init/1","type":"function"},{"doc":"Inserts and sorts item on ranking. Params: id: integer, UUID, etc. new_score: integer or float detail: might be the name of a person on the raking or any other detail related to the id.","ref":"Rankex.html#insert/3","title":"Rankex.insert/3","type":"function"},{"doc":"Inserts and sorts item on ranking (of named table).","ref":"Rankex.html#insert/4","title":"Rankex.insert/4","type":"function"},{"doc":"Gives the position/rank for an item with given id. This is much slower than position/1 once the table is sorted by score.","ref":"Rankex.html#position_by_id/1","title":"Rankex.position_by_id/1","type":"function"},{"doc":"Gives the position/rank for an item with given id (in named table). This is much slower than position/2 once the table is sorted by score.","ref":"Rankex.html#position_by_id/2","title":"Rankex.position_by_id/2","type":"function"},{"doc":"Gives the position/rank for an item with given score.","ref":"Rankex.html#position_in/2","title":"Rankex.position_in/2","type":"function"},{"doc":"Gives the position/rank for an item with given score (in named table).","ref":"Rankex.html#position_in/3","title":"Rankex.position_in/3","type":"function"},{"doc":"Returns the top N items of the ranking. format for the modes: :tuples : [{{score, id}, detail}, ...] :map_list : [%{id: id, detail: detail, score: score}, ...] :position_map : %{1: %{id: id, detail: detail, score: score}, 2: ...} :score_position_map : %{score: %{id: id, detail: detail, position: position}, 2: ...}","ref":"Rankex.html#top/2","title":"Rankex.top/2","type":"function"},{"doc":"Returns the top N items of the ranking (for a named table).","ref":"Rankex.html#top/3","title":"Rankex.top/3","type":"function"},{"doc":"Updates score and position of an item on ranking.","ref":"Rankex.html#update/4","title":"Rankex.update/4","type":"function"},{"doc":"Updates score and position of an item on ranking (of named table).","ref":"Rankex.html#update/5","title":"Rankex.update/5","type":"function"},{"doc":"RankEx A ranking/leaderboard library for Elixir based on ETS. It maps score (integer or float) to a integer id or UUID along with any other data (name of the ranker). It&#39;s leveraged on ETS ordered set once it can also order some kinds of records with a tuple as key. This way all operations regarding sorting is given for granted within a bulletproof cache. For performance reasons, update and delete operations require the previous score which allows this mapping (id-&gt;score) to be stored in users cache without duplicity. Supports: Fast insertion Fast update Fast delete Position by score (thousand reads in 300ms) or id Detail field that might be used for rank names or other info All with operation for tied score Multiple tables Top N results in different formats: :tuples : [{{score, id}, detail}, ...] :map_list : [%{id: id, detail: detail, score: score}, ...] :position_map : %{1: %{id: id, detail: detail, score: score}, 2: ...} :score_position_map : %{score_value =&gt; %{id: id, detail: detail, position: position}, ...} Benchmarking insert/3 for 10000 items: 30ms After inserting one million records: delete/2 for 10000 items: 7ms update/4 for 10000 items: 37ms position_in/1 for 1000 items: 310ms Running on Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz and DDR4 2400 MT/s","ref":"readme.html","title":"RankEx","type":"extras"},{"doc":"If available in Hex, the package can be installed by adding benchmarking to your list of dependencies in mix.exs: def deps do [ {:rankex, &quot;~&gt; 0.1.0&quot;} ] end Documentation can be generated with ExDoc and published on HexDocs. Once published, the docs can be found at https://hexdocs.pm/benchmarking.","ref":"readme.html#installation","title":"RankEx - Installation","type":"extras"}]