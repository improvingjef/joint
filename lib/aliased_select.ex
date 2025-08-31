defmodule Joint.AliasedSelect do
  @moduledoc """
  Provides a macro for generating aliased select queries in Ecto.

  The `aliased_select/3` macro simplifies the creation of Ecto queries by allowing you to
  select fields from a query source and alias them in the result map. It generates a
  structured map where fields are prefixed with their alias, making it easier to work with
  complex queries involving multiple bindings.

  ## Usage
  This macro is designed to be used with Ecto's query syntax, specifically with `select/3`
  or `select_merge/3`. It takes a query, a kind (e.g., `:select` or `:select_merge`), and
  a list of tuples specifying aliases and their associated fields. The macro constructs a
  query that binds the source and maps the selected fields into a result map with aliased
  keys.

  ### Parameters
  - `kind`: An atom specifying the type of select operation (e.g., `:select` or `:select_merge`).
  - `query`: The Ecto query to operate on.
  - `expr`: A list of tuples in the format `{alias, fields}`, where `alias` is an atom
    representing the binding alias, and `fields` is a list of atoms representing the fields
    to select from that alias.

  ### Returns
  A quoted expression that generates an Ecto query with the specified fields selected and
  aliased in the result map.

  ## Example
  ```elixir
  import Joint.AliasedSelect

  query = from(u in User, as: :user)
  aliased_select(:select, query, [{:user, [:id, :name]}])
  # this generates a query similar to
  from(u in User, as: :user, select: %{user_id: u.id, user_name: u.name})
  """

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
