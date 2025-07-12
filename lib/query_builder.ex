defmodule Joint.QueryBuilder do
  alias Joint.Graph
  import Ecto.Query

  def build(%Graph{} = graph) do
    graph.queryable
    |> Ecto.Query.from(as: ^graph.as)
    |> then(&do_join(&1, graph.as, graph.joins))

    # |> distinct(true)
  end

  def do_join(query, as, joins) do
    Enum.reduce(joins, query, fn
      join, query ->
        query
        |> join(:inner, [{^as, p}], x in assoc(p, ^join.field), as: ^join.as)
        |> do_join(join.as, join.joins)
    end)
  end
end
