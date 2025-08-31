defmodule Joint.Web.Column do
  defstruct header: nil,
            alias: nil,
            field: nil,
            fields: nil,
            sortable: false,
            filterable: false,
            value: nil
end

defmodule Joint.Web.Action do
  defstruct url: nil,
            method: nil,
            confirm?: false,
            label: nil,
            icon: nil
end

defmodule Joint.Web.Table do
  @moduledoc """
  A macro-based DSL for defining dynamic table configurations for Phoenix applications.

  `Joint.Web.Table` provides a framework for defining table structures to display data from Ecto schemas in a Phoenix application, typically rendered with the `Joint.Web.Stable` component. It allows developers to specify columns, fields, and actions for a given Ecto schema, automatically generating queries and column metadata for rendering sortable and filterable tables.

  ## Features
  - **Column Definitions**: Define table columns with fields, headers, sorting, and filtering options using the `column/1` macro.
  - **Nested Associations**: Support for querying and displaying fields from associated schemas (e.g., `{:user, :email}` or `{:user, person: :name}`).
  - **Query Generation**: Automatically builds Ecto queries based on the defined fields and associations using the `query/0` function.
  - **Graph Traversal**: Leverages `Joint.Graph` to traverse schema associations and construct aliased queries.
  - **Extensibility**: Supports custom actions via the `Joint.Web.Action` struct for table row interactions.

  ## Usage
  To use `Joint.Web.Table`, a module must `use Joint.Web.Table` and define a table configuration with the `table/2` macro, specifying the Ecto schema and its columns. The module then exposes functions like `columns/0`, `resource/0`, `graph/0`, and `query/0` for integration with Phoenix components.

  ### Example
  ```elixir
  defmodule RoastTable do
    use Joint.Web.Table

    table Joint.Coffee.Roast do
      column field: :roast_date, sortable: true
      column field: :start_time, sortable: true
      column field: {:user, person: :name}, sortable: true, header: "Roaster"
      column field: {:roaster, :name}, sortable: true, header: "Machine"
      column fields: [:roasted_weight, weight_unit: :symbol], sortable: true, header: "Roasted Weight"
    end
  end
  ```

  This defines a table for the Joint.Coffee.Roast schema with sortable columns for roast_date, start_time, a nested user.person.name field (labeled "Roaster"), and more.
  ### Generated Functions

  * columns/0: Returns a list of Joint.Web.Column structs defining the table's columns.
  * resource/0: Returns the Ecto schema module (e.g., Joint.Coffee.Roast).
  * graph/0: Returns the graph of fields and associations for query construction.
  * query/0: Returns an Ecto query for fetching data, incorporating fields and associations.

  ### Integration with Phoenix
  The table module is typically used with a Phoenix component like Joint.Web.TableComponent or Joint.Web.Stable.stable/1, which renders the table with formatted values and sorting controls. For example:

  <.table
    id="roast-table"
    table_module={RoastTable}
    records={RoastTable.query() |> Repo.all()}
    order_by={@order_by}
    direction={@direction}
  />

  ### Column Configuration
  The column/1 macro accepts options to customize each column:

  * field: An atom, tuple (e.g., {:user, :email}), or list of fields (e.g., [:roasted_weight, weight_unit: :symbol]) to display.
  * header: A custom string for the column header (defaults to humanized field name).
  * sortable: A boolean indicating if the column is sortable (default: false).
  * filterable: A boolean indicating if the column is filterable (default: false).
  * value: An optional function to compute the column's value dynamically.
  * fields: A list of fields for composite columns (e.g., combining roasted_weight and weight_unit).

  ### Query Building

  The module uses Joint.Graph and Joint.QueryBuilder to construct Ecto queries that include necessary joins and aliased selections for nested fields. The as_select/2 function flattens the graph into a query-compatible format, handling associations and field aliases.
  ### Limitations

  Assumes unique association names in the query to avoid naming collisions (e.g., multiple joins to the same schema are not fully supported).
  Sorting on deeply nested fields (e.g., {:user, person: :name}) may require custom query logic in the calling LiveView.

  ### Related Modules

  * Joint.Web.Column: Struct for column definitions.
  * Joint.Web.Action: Struct for defining row actions (not used in provided examples).
  * Joint.Graph: Handles schema traversal and query construction.
  * Joint.QueryBuilder: Builds Ecto queries from the graph.
  * Joint.Web.Stable: Provides utilities for formatting and rendering tables.

  For advanced usage, such as custom sorting or filtering, extend the generated query/0 function or handle events in a Phoenix LiveView.
  """

  import Ecto.Query.API, only: [field: 2]
  import Ecto.Query, only: [select: 3]
  import Joint.AliasedSelect

  defmacro __using__(_) do
    quote location: :keep do
      alias Joint.Web.Action
      alias Joint.Web.Column
      import Ecto.Query, only: [select_merge: 3, select: 3]
      import Joint.Web.Table
      import Joint.Queries.AliasedSelect

      Module.register_attribute(__MODULE__, :columns, accumulate: true)
      Module.register_attribute(__MODULE__, :actions, accumulate: true)
      Module.register_attribute(__MODULE__, :resource, accumulate: false)
      Module.register_attribute(__MODULE__, :graph, accumulate: true)
      Module.register_attribute(__MODULE__, :select, accumulate: true)
      Module.register_attribute(__MODULE__, :source, accumulate: false)
    end
  end

  defmacro table(module, do: block) do
    {_, _, list} = module
    last = List.last(list)

    source =
      last
      |> Atom.to_string()
      |> String.downcase()
      |> String.to_atom()

    prelude =
      quote location: :keep do
        Module.put_attribute(__MODULE__, :source, unquote(source))
        Module.put_attribute(__MODULE__, :resource, unquote(module))
        unquote(block)
        Module.put_attribute(__MODULE__, :select, as_select(unquote(source), @graph))
      end

    postlude =
      quote location: :keep, unquote: false do
        def resource, do: @resource
        def columns, do: @columns
        def graph, do: @graph

        def query do
          query =
            @resource
            |> Joint.Graph.visit(@graph)
            |> Joint.QueryBuilder.build()

          aliased_select(:select, query, unquote_splicing(Macro.escape(@select)))
        end

        # defstruct graph: @graph, resource: @resource, columns: @columns, actions: @actions
      end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end

  # this makes an assumption that all association names in the query are unique.
  # this may not be true in some cases, but we're not dealing with the case that we have
  # a similar join. For instance, we might have two different users in different roles,
  # each of which would join against person. This would create a naming collision. If we
  # were to fully flatten names, e.g. role1_person_name: ..., role2_person_name: ...,
  # it would address it.
  #
  # Iterate over the graph and flatten out a list of associations and fields.
  # This should really be more of a traverse, but we're keeping it simple for now.
  def as_select(source, graph) do
    graph
    |> Enum.map(fn
      {_assoc, {nested_assoc, field}} when is_atom(field) -> {nested_assoc, [field]}
      {assoc, field} when is_atom(field) -> {assoc, [field]}
      {_assoc, [{nested_assoc, field}]} when is_atom(field) -> {nested_assoc, [field]}
      {assoc, list} when is_list(list) -> {assoc, list}
      field when is_atom(field) -> {source, [field]}
    end)
    |> Enum.group_by(fn {assoc, _} -> assoc end)
    |> Enum.map(fn {assoc, list} ->
      {assoc,
       Enum.map(list, fn
         {_assoc, field} when is_atom(field) -> field
         {_assoc, [field]} -> field
       end)}
    end)
  end

  # TODO: generate column names from field when tuple, e.g.
  # {:user, :email} -> :user_email
  # TODO: generate header from field when tuple, e.g.
  # {:user, :email} -> "User Email"
  defmacro column(opts) do
    quote location: :keep do
      column = struct(Joint.Web.Column, unquote(opts))

      Module.put_attribute(__MODULE__, :columns, column)

      if is_list(column.fields) do
        Enum.each(column.fields, fn field ->
          Module.put_attribute(__MODULE__, :graph, field)
        end)
      else
        Module.put_attribute(__MODULE__, :graph, column.field)
      end

      Module.get_attribute(__MODULE__, :graph)
    end
  end

  defmacro map_(variable, prefix, atom_list) do
    pairs =
      Enum.map(atom_list, fn atom ->
        key = :"#{prefix}_#{atom}"
        {key, quote(do: unquote(variable).unquote(atom))}
      end)

    quote do: Enum.into(unquote(pairs), %{})
  end

  def source_alias(query) do
    query.aliases
    |> Enum.filter(fn {_, v} -> v == 0 end)
    |> Enum.at(0)
    |> elem(0)
  end

  def name(first, second) when is_atom(first) and is_atom(second) do
    String.to_atom("#{first}_#{second}")
  end
end
