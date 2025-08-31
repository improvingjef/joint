defmodule Joint.LikeQuery do
  alias Joint.Graph
  alias Joint.QueryBuilder
  import Ecto.Query
  import Joint.Ecto, only: [string: 1]

  def query(graph), do: graph |> QueryBuilder.build()
  # def to_query(clause, %Graph{} = graph), do: graph |> query() |> where(^clause)
  def to_query(clause, %Ecto.Query{} = query), do: where(query, ^clause)

  def like(module, searchable, search_term, query) when is_binary(search_term) do
    like(module, search_term, Graph.visit(module, searchable), query)
  end

  def like(_module, search_term, %Graph{} = graph, %Ecto.Query{} = query) do
    search_term
    |> String.trim()
    |> String.split()
    |> Enum.split_with(&String.starts_with?(&1, "-"))
    |> to_keyword_list()
    |> to_clauses(to_filters(graph))
    |> to_query(query)
  end

  def like(module, searchable, search_term) when is_binary(search_term) do
    graph = Graph.visit(module, searchable)
    like(module, search_term, graph, query(graph))
  end

  def to_keyword_list({excludes, includes}) when is_list(excludes) and is_list(includes) do
    [
      not: excludes |> Enum.map(&String.replace(&1, "-", "")) |> Enum.map(&wildcard/1),
      like: Enum.map(includes, &wildcard/1)
    ]
  end

  def wildcard(string), do: "%#{string}%"

  def to_filters(graph) do
    graph |> flatten() |> Enum.flat_map(&to_filter/1)
  end

  def to_filter(%Graph{search_params: params, as: as}) do
    Enum.map(params, fn {field, type} -> {field, type, as} end)
  end

  def to_clauses(terms, filters) do
    Enum.reduce(terms, true, &to_and_clauses(&2, &1, filters))
  end

  def to_and_clauses(clause, {_, []}, _filters), do: clause

  def to_and_clauses(clause, {which, terms}, filters) do
    and_clause(clause, clauses(filters, which, terms))
  end

  def to_or_clauses(clause, {_, []}, _filters), do: clause

  def to_or_clause(clause, term, filters, which) do
    or_clause(clause, clause(term, filters, which))
  end

  def clauses(filters, which, terms) do
    Enum.reduce(terms, false, &to_or_clause(&2, &1, filters, which))
  end

  def clause(term, filters, which) do
    filters
    |> Enum.reduce(false, fn {field, type, as}, clause ->
      or_clause(clause, like_clause(field, type, as, term))
    end)
    |> maybe_not(which)
  end

  # def maybe_not(true, :not), do: false
  # def maybe_not(false, :not), do: true
  def maybe_not(clause, :not), do: dynamic(not (^clause))
  def maybe_not(clause, _), do: clause

  def flatten(%{joins: joins} = graph), do: [graph | Enum.flat_map(joins, &flatten(&1))]

  def like_clause(field, type, as, like) do
    field |> reference(as) |> string_clause(type) |> like_clause(like)
  end

  def reference(field, alias) do
    dynamic([{^alias, x}], field(x, ^field))
  end

  def like_clause(clause, like), do: dynamic(ilike(^clause, ^like))
  def string_clause(field_clause, :string), do: field_clause
  def string_clause(field_clause, _), do: dynamic(string(^field_clause))
  def or_clause(left, right) when left == false or right == false, do: left || right
  def or_clause(left, right), do: dynamic(^left or ^right)
  def and_clause(true, right), do: right
  def and_clause(left, true), do: left
  def and_clause(left, right), do: dynamic(^left and ^right)
  def any_clause(clauses), do: Enum.reduce(clauses, false, &or_clause(&1, &2))
  def all_clause(clauses), do: Enum.reduce(clauses, true, &and_clause(&1, &2))
end
