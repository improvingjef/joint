defmodule Joint.AtomType do
  @behaviour Ecto.Type
  def type, do: :atom
  def cast(value), do: {:ok, value}
  def load(value), do: {:ok, String.to_atom(value)}
  def dump(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def dump(_), do: :error
  def embed_as(_), do: :self
  def equal?(a, b), do: a == b
end

defmodule Joint.ColumnType do
  @moduledoc """
  A custom Ecto type for handling column names.
  This type is used to convert between a string representation and a tuple representation.

  Consider the following query:

  query =
    from u in User,
    join: p in assoc(u, :person),
    preload: [:person]

  We can represent this query as follows:

  q = q(User, [:person])

  To allow multiple joins to the same schema and dynamic expressions, the query will be aliased as follows:

  query =
    from u in User, as: :user,
    join: p in assoc(u, :person), as: :user_person,
    preload: [:person]

  A column may be one of:
  - an atom, e.g. `:email`
  - a tuple of atoms, e.g. `{:user, :email}`
  - a nested tuple of atoms, e.g. `{:user, {:person, :name}}`

  In live_view urls, we use struct notation to refer to columns, e.g. `user.email`.

  In a url, we use a dot to separate the atoms, e.g. `user.person.name`.
  So a single atom will simply be a string, e.g. `email`.
  A tuple of atoms will be a string with an underscore, e.g. `user.email`.
  A nested tuple of atoms will be a string with an underscore, e.g. `user_person.name`.

  however, in aliased queries, the dot-separated string is converted to a two element tuple,
  e.g. `user.person.name` -> `{:user_person, :name}`. This will allow the column to be used
  in the 'order_by' clause of a query.

  Additionally, the first element of the tuple is not the source of the query but instead the
  name of the association. The source is always aliased to a lowercase atom based on the schema name.
  So the lifecycle of transformations is as follows:
  tuple -> dot-separated string -> aliased tuple.
  Since this type exists almost exclusively for QueryParams, it is primarily focused on converting
  between the dot-separated string and the non-aliased tuple. So perhaps the conversion to an
  aliased tuple should be done in the QueryParams module.
  """
  @behaviour Ecto.Type
  def type, do: :tuple
  def cast(value), do: {:ok, value}

  def load(value) do
    if String.contains?(value, ".") do
      {:ok, dot_separated_to_aliased_string_tuple(value)}
    else
      {:ok, String.to_existing_atom(value)}
    end
  end

  # Convert a dot-separated string to a tuple of atoms, e.g.
  # "user.person.name" -> {"user_person", "name"}
  def dot_separated_to_aliased_string_tuple(value) do
    value
    |> String.split(".")
    |> Enum.reverse()
    |> Enum.reduce(nil, fn
      x, nil -> x
      x, {y, z} -> {x <> "_" <> y, z}
      x, y -> {x, y}
    end)
  end

  def dump(value) when is_tuple(value) do
    dumped =
      value
      |> Tuple.to_list()
      |> Enum.map_join(".", &Atom.to_string/1)

    {:ok, dumped}
  end

  def dump(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def dump(_), do: :error
  def embed_as(_), do: :self
  def equal?(a, b), do: a == b
end
