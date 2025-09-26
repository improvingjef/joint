defmodule Joint.Q do
  @moduledoc """
  Features supported by Ecto.Query that are not yet supported:
  Joint is a module that provides
  a minimally terse specification for a subset of Ecto queries.
  As an example, the following query:
  from o in Order,
  join: c in assoc(o, :customer),
  join: i in assoc(o, :items),
  join: f in assoc(i, :offering),
  preload: [customer: c, items: {i, [offering: f]}]

  can be represented as:
  query(Order, [customer:, items: :offering])

  all join types are supported, including:
  - inner_join
  - left_join
  - right_join
  - cross_join
  - cross_lateral_join
  - full_join
  - inner_lateral_join
  - left_lateral_join
  - array_join
  - left_array_join

  In the above example, if we were to add a left_join to the query for items,

  from o in Order,
  join: c in assoc(o, :customer),
  left_join: i in assoc(o, :items),
  left_join: f in assoc(i, :offering),
  preload: [customer: c, items: {i, [offering: f]}]

  it would look like:
  query(Order, [:customer, left_join: [items: :offering])

  All joins are preloaded.
  """
  defmacro __using__(_) do
    quote do
      import Joint.Q, only: [q: 2, build: 3]
    end
  end

  def build(module, attrs, env) do
    expand_from(module, attrs, env)
  end

  def module({:__aliases__, _, module_parts}) when is_list(module_parts) do
    Module.concat(module_parts)
  end

  def module(module_parts) when is_list(module_parts) do
    Module.concat(module_parts)
  end

  def module(module) when is_atom(module) do
    module
  end

  def module_name({:__aliases__, _, module_parts}) do
    List.last(module_parts)
  end

  def module_name({:module, _, name}), do: module_name(name)

  def module_name(module) do
    module
    |> Module.split()
    |> List.last()
    |> String.to_atom()
  end

  def expand_module(module) do
    module_name = module_name(module)
    module = module(module)
    as = dbg(module_name |> Macro.underscore() |> String.to_atom())
    {{:__aliases__, [alias: module], [module_name]}, as}
  end

  def expand_from(module, attrs, env) do
    {{_, [alias: _m], _} = module_alias, as} = expand_module(module)

    source_variable = {:v, [], env}
    in_expr = {:in, [context: env, imports: [{2, Kernel}]], [source_variable, module_alias]}
    as_expr = {:as, as}

    join_attrs = Joint.AssociationGraphBuilder.walk(module(module), attrs)
    joins_expr = expand_joins(:v, join_attrs, nil, env)
    {preload_expr, _, _, _} = expand_preloads(join_attrs, source_variable, 0, env)
    preloads = [preload: preload_expr]
    # include_select = Enum.any?(graph.search_params)
    # selects =
    #   if include_select do
    #     {select_exprs, _, _, _} = expand_select(graph.search_params, as, 0, env)
    #     [select: {:%{}, [], select_exprs}]
    #   else
    #     []
    #   end
    {:from, [context: env, imports: [{1, Ecto.Query}, {2, Ecto.Query}]],
     [in_expr, [as_expr | joins_expr ++ preloads]]}
  end

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

  def flatten([item], {index, parent, as_prefix, join, acc}) do
    flatten(item, {index, parent, as_prefix, join, acc})
  end

  def flatten(list, {index, parent, as_prefix, join, acc}) when is_list(list) do
    Enum.reduce(list, {index, parent, as_prefix, join, acc}, &flatten(&1, &2))
  end

  def flatten(atom, {index, parent, nil, join, acc}) when is_atom(atom) do
    {index + 1, parent, nil, join, [{parent, :"v#{index}", atom, atom, join} | acc]}
  end

  def flatten(atom, {index, parent, as_prefix, join, acc}) when is_atom(atom) do
    {index + 1, parent, as_prefix, join,
     [{parent, :"v#{index}", atom, :"#{as_prefix}_#{atom}", join} | acc]}
  end

  def flatten({join_type, child}, {index, parent, as_prefix, join, acc})
      when join_type in @join_types do
    {new_index, _, _, _, fields} = flatten(child, {index, parent, as_prefix, join_type, []})
    {new_index, parent, as_prefix, join, fields ++ acc}
  end

  def flatten({atom, child}, {index, parent, as_prefix, join, acc}) do
    var = :"v#{index}"
    as = if as_prefix == nil, do: atom, else: :"#{as_prefix}_#{atom}"

    {new_index, _, _, _, fields} = flatten(child, {index + 1, var, as, join, []})
    {new_index, parent, as_prefix, join, fields ++ [{parent, var, atom, as, join} | acc]}
  end

  # def expand_select(list, module_alias, index, env) when is_list(list) do
  #   {acc, _, _, _} = Enum.reduce(list, {[], module_alias, index, env}, &expand_select/2)
  # end

  # def expand_select(assoc, {acc, module_alias, index, env}) when is_atom(assoc) do
  #   field = {:"#{module_alias}_#{assoc}", {{:., [], [{:"v#{index}", [], env}, assoc]}, [no_parens: true], []}}
  #   {[field | acc], module_alias, index + 1, env}
  # end

  # def expand_select({assoc, children}, {acc, module_alias, index, env}) when is_atom(assoc) do
  #   {children_exprs, _, new_index, _} = expand_select(children, {[], assoc, index, env})
  #   {children_exprs ++ acc, module_alias, new_index + 1, env}
  # end

  def expand_joins(source_variable, attrs, as_prefix, env) do
    {_, _, _, _, joins} = flatten(attrs, {0, source_variable, as_prefix, :join, []})

    joins
    |> Enum.map(&expand_join(&1, env))
    |> Enum.reduce([], fn {join_expr, as_expr}, acc -> [join_expr, as_expr | acc] end)
  end

  def expand_join({parent_variable, child_variable, assoc, as, join}, env) do
    parent_var = {parent_variable, [], env}
    child_var = {child_variable, [], env}

    join_expr =
      {join,
       {:in, [context: env, imports: [{2, Kernel}]],
        [child_var, {:assoc, [], [parent_var, assoc]}]}}

    as_expr = {:as, as}
    {join_expr, as_expr}
  end

  def expand_preloads(list, parent_variable, index, env) when is_list(list) do
    Enum.reduce(list, {[], parent_variable, index, env}, &expand_preload/2)
  end

  def expand_preload({join_type, children}, {preload_acc, parent_variable, index, env})
      when join_type in @join_types do
    {preload_expr, _, new_index, _} = expand_preloads(children, parent_variable, index, env)
    {List.wrap(preload_expr) ++ preload_acc, parent_variable, new_index, env}
  end

  def expand_preload({assoc, child}, {preload_acc, parent_variable, index, env})
      when is_atom(assoc) do
    join_variable = {:"v#{index}", [], env}
    {child_preload, _, new_index, _} = expand_preload(child, {[], join_variable, index + 1, env})

    {
      [{assoc, {join_variable, child_preload}} | preload_acc],
      parent_variable,
      new_index,
      env
    }
  end

  def expand_preload(assoc, {preload_acc, parent_variable, index, env}) when is_atom(assoc) do
    join_variable = {:"v#{index}", [], env}
    {[{assoc, join_variable} | preload_acc], parent_variable, index + 1, env}
  end

  def expand_preload(associations, {_preload_acc, parent_variable, index, env})
      when is_list(associations) do
    expand_preloads(associations, parent_variable, index, env)
  end

  defmacro q(module, joins) do
    query = build(module, joins, __CALLER__.module)

    quote do
      import Ecto.Query
      unquote(query)
    end
  end
end
