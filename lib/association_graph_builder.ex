# TODO: Rename this to something more descriptive
defmodule Joint.AssociationGraphBuilder do
  @moduledoc """
  This module accepts a nested list of associations and fields,
  prunes the fields, and returns the remaining list of associations.
  """
  @join_types [
    :inner_join,
    :left_join,
    :right_join,
    :cross_join,
    :cross_lateral_join,
    :full_join,
    :inner_lateral_join,
    :left_lateral_join,
    :array_join,
    :left_array_join
  ]

  def walk(_module, []), do: []

  def walk(module, list) when is_list(list) do
    {_, walked} = Enum.reduce(list, {module, []}, &walk/2)
    Enum.reverse(walked)
  end

  def walk({join_type, children}, {module, acc}) when join_type in @join_types do
    {module, [{join_type, walk(module, children)} | acc]}
  end

  def walk(candidate, {module, acc}) do
    if assoc?(module, candidate) do
      {module, [walk_association(module, candidate) | acc]}
    else
      {module, acc}
    end
  end

  def walk_association(_module, assoc) when is_atom(assoc) do
    assoc
  end

  def walk_association(module, {field, child}) when is_atom(child) do
    association = module.__schema__(:association, field)

    case walk(association.related, [child]) do
      [] -> field
      walked -> {field, walked}
    end
  end

  def walk_association(module, {field, children}) when is_list(children) do
    association = module.__schema__(:association, field)

    case walk(association.related, children) do
      [] -> field
      walked -> {field, walked}
    end
  end

  def assoc?(module, field) do
    module.__schema__(:associations)
    |> Enum.member?(name(field))
  end

  def name(field) when is_atom(field), do: field
  def name({field, _}) when is_atom(field), do: field
end
