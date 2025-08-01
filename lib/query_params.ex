defmodule Joint.OrderBy do
  import Ecto.Query, only: [order_by: 3]

  def sort(query, [{direction, {assoc, sort_field}}]) do
    order_by(query, [{^assoc, x}], {^direction, field(x, ^sort_field)})
  end
end

defmodule Joint.QueryParams do
  use Ecto.Schema
  import Ecto.Query
  import Joint.OrderBy, only: [sort: 2]
  alias Joint.ColumnType

  embedded_schema do
    field(:offset, :integer, default: 0)
    field(:limit, :integer)
    field(:order_by, Joint.ColumnType)
    field(:direction, Ecto.Enum, values: [:asc, :desc])
    field(:search, :string, default: "")
    field(:filters, :map)
  end

  def load(params, default_order_by \\ :inserted_at, default_limit \\ 100) do
    %__MODULE__{
      order_by: Map.get(params, "order_by", default_order_by),
      direction: direction(Map.get(params, "direction", :asc)),
      search: Map.get(params, "search", ""),
      limit: Map.get(params, "limit", default_limit),
      filters: %{}
    }
  end

  def to_order_by(order_by) when is_atom(order_by), do: order_by

  def to_order_by(order_by) when is_binary(order_by) do
    if String.contains?(order_by, ".") do
      order_by
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)
      |> Enum.reverse()
      |> Enum.reduce(nil, fn
        x, nil -> x
        x, y -> {x, y}
      end)
    else
      String.to_atom(order_by)
    end
  end

  def direction("desc"), do: :desc
  def direction("asc"), do: :asc
  def direction(dir) when dir in [:asc, :desc], do: dir

  def previous(query, %__MODULE__{} = params) do
    current(query, %{params | offset: max(0, params.offset - params.limit)})
  end

  def next(query, %__MODULE__{} = params) do
    current(query, %{params | offset: params.offset + params.limit})
  end

  def current(query, %__MODULE__{} = params) do
    query
    |> and_with(:limit, params.limit)
    |> and_with(:offset, params.offset)
    |> and_with(:order_by, [{params.direction, params.order_by}])
    |> then(&{&1, %{params | direction: opposite(params.direction)}})
  end

  # the and_with functions are used to build up the query
  # in a way that allows the optional inclusion of features
  # like limit, offset, order_by, etc.
  # Since those functions of Ecto.Query are imported,
  # we don't use the simpler naming here.
  def and_with(query, :limit, nil), do: query
  def and_with(query, :limit, :all), do: query
  def and_with(query, :limit, limit), do: limit(query, ^limit)

  def and_with(query, :offset, 0), do: query
  def and_with(query, :offset, nil), do: query
  def and_with(query, :offset, offset), do: offset(query, ^offset)

  def and_with(query, :order_by, [{_, nil}]), do: query

  def and_with(query, :order_by, [{direction, field}]) when is_tuple(field) do
    sort(query, [{direction, field}])
  end

  def and_with(query, :order_by, [{direction, field}]) when is_binary(field) do
    if String.contains?(field, ".") do
      {key, value} = ColumnType.dot_separated_to_aliased_string_tuple(field)
      sort(query, [{direction, {String.to_atom(maybe_alias(key, query)), String.to_atom(value)}}])
    else
      and_with(query, :order_by, [{direction, String.to_existing_atom(field)}])
    end
  end

  def and_with(query, :order_by, [{direction, field}])
      when direction in [:asc, :desc] and
             is_atom(field),
      do: order_by(query, ^{direction, field})

  # TODO: I'm accessing the Ecto.Query struct directly here.
  # I should accumulate metadata when I build the query.
  # TODO: More deeply nested columns
  # TODO: Multi-field columns
  def and_with(query, :order_by, [{direction, {assoc, field}}])
      when direction in [:asc, :desc] and
             is_atom(field) and
             is_atom(assoc) do
    {alias_index, _} = Keyword.get(query.assocs, assoc)

    as_alias =
      query.aliases
      |> Enum.filter(fn {_, value} -> value == alias_index end)
      |> Enum.map(fn {key, _} -> key end)
      |> List.first()

    sort(query, [{direction, {as_alias, field}}])
  end

  def maybe_alias(key, %{aliases: %{}}), do: key

  def maybe_alias(key, %{aliases: aliases}) do
    {alias, _} = Enum.find(aliases, fn {_, value} -> value == key end)
    alias
  end

  def opposite(:asc), do: :desc
  def opposite(:desc), do: :asc
end
