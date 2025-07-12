defmodule Joint.AliasedSelect do
  defmacro aliased_select(kind, query, expr) do
    meta = [line: __CALLER__.line]

    {binding_expr, mapped_expr} =
      expr
      |> Enum.with_index()
      |> Enum.reduce(
        {[], []},
        fn
          {{alias, fields}, index}, acc ->
            bind_aliased_fields(acc, index, alias, fields, meta)
        end
      )

    quote do
      unquote(kind)(
        unquote(query),
        unquote(Enum.reverse(binding_expr)),
        unquote({:%{}, meta, mapped_expr})
      )
    end
  end

  def bind_aliased_fields({bindings, expr}, index, alias, fields, meta) when is_list(fields) do
    var = {:"v#{index}", meta, nil}

    fields
    |> Enum.map(&alias_field(alias, var, &1, meta))
    |> Enum.concat(expr)
    |> then(&{[{alias, var} | bindings], &1})
  end

  def alias_field(alias, var, field, [line: line] = meta) do
    {:"#{alias}_#{field}", {{:., meta, [var, field]}, [no_parens: true, line: line], []}}
  end
end
