defmodule Joint.Graph do
  @moduledoc """
  A graph is a data structure that traverses resource/model graph. It is used to:
  - build queries for the database, e.g. LikeQuery, NotLikeQuery
  - replace ecto queries with a simpler graph expression
  - import and export data from a resource graph structure
  """

  alias Joint.Graph

  defstruct as: nil,
            nested: false,
            queryable: nil,
            field: nil,
            joins: [],
            search_params: [],
            optional: false

  def to_as(module) do
    Module.split(module)
    |> List.last()
    |> Macro.underscore()
    |> String.to_atom()
  end

  def is_in(attr, which, graph) when which in [:fields, :associations],
    do: attr in graph.queryable.__schema__(which)

  def visit(module, fields) do
    visit(module, fields, false)
  end

  def visit(module, fields, optional) when is_atom(module) and is_list(fields) do
    visit(to_as(module), module, fields, optional, false)
  end

  def visit(%Graph{} = graph, fields, optional) when is_list(fields) do
    Enum.reduce(fields, graph, fn field, graph -> visit(graph, field, optional) end)
  end

  def visit(%Graph{} = graph, attr, optional) when is_atom(attr) do
    cond do
      attr |> is_in(:fields, graph) ->
        field(graph, {attr, graph.queryable.__schema__(:type, attr)})

      attr |> is_in(:associations, graph) ->
        association(graph, attr, [], optional)

      true ->
        raise "Field #{attr} not found in #{graph.queryable}"
    end
  end

  def visit(graph, {join_type, fields}, _optional)
      when join_type in [:left_join, :right_join, :full_join] do
    visit(graph, fields, true)
  end

  def visit(graph, {assoc, fields}, optional)
      when (is_atom(assoc) and is_list(fields)) or is_atom(fields) do
    if assoc |> is_in(:associations, graph) do
      IO.inspect(assoc,
        label: "visiting association ############################################"
      )

      association(graph, assoc, fields, optional)
    else
      raise "Association #{assoc} not found in #{graph.queryable}"
    end
  end

  def visit(as, module, field, optional, nested)
      when is_atom(as) and is_atom(module) and is_atom(field) do
    visit(as, module, [field], optional, nested)
  end

  def visit(as, module, fields, optional, nested)
      when is_atom(module) and is_atom(as) and is_list(fields) do
    graph =
      visit(
        %Graph{nested: nested, queryable: module, as: as, optional: optional},
        fields,
        optional
      )

    %{graph | search_params: Enum.reverse(graph.search_params), joins: Enum.reverse(graph.joins)}
  end

  def field(graph, field) do
    IO.inspect(field, label: "field ############################################")
    %{graph | search_params: [field | graph.search_params]}
  end

  def association(graph, assoc, fields, optional) do
    IO.inspect(assoc, label: "association ############################################")
    association = graph.queryable.__schema__(:association, assoc)
    as = if graph.nested, do: :"#{graph.as}_#{association.field}", else: association.field
    sub_search = visit(as, association.related, fields, optional, true)
    sub_search = %{sub_search | field: association.field}
    %{graph | joins: [sub_search | graph.joins]}
  end
end
