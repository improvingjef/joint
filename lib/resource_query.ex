# Graph:

# ResourceQuery: 132 - macros
# AliasedSelect: 32 - macros - combine with ResourceQuery

# LikeQuery: 73 - dynamics, no macros
# QueryParams: 61 - no macros

# Total: 318

defmodule Joint.ResourceQuery do
  def build_query(which, opts, module) do
    model = Keyword.get(opts, :model, Module.get_attribute(module, :model))
    metadata = Keyword.get(opts, which, [])

    cond do
      metadata != [] -> Joint.Q.build(model, metadata, module)
      is_nil(model) -> nil
      true -> model.index_query() |> Macro.escape()
    end
  end

  defmacro __using__(opts) do
    use Joint.Q

    alias Joint.Repo

    model = Keyword.get(opts, :model, Module.get_attribute(__CALLER__.module, :model))
    index = Keyword.get(opts, :index, [])
    search = Keyword.get(opts, :search, [])
    index_query = build_query(:index, opts, __CALLER__.module)

    # IO.inspect(Macro.to_string(index_query), label: "index_query -------------------------------")
    search_query = build_query(:search, opts, __CALLER__.module)

    # IO.inspect(Macro.to_string(search_query), label: "search_query -------------------------------")

    quote location: :keep do
      import Ecto.Query
      alias Joint.QueryParams

      Module.register_attribute(__MODULE__, :model, persist: false)
      Module.register_attribute(__MODULE__, :index, persist: false)
      Module.register_attribute(__MODULE__, :search, persist: false)
      Module.register_attribute(__MODULE__, :index_query, persist: false)
      Module.register_attribute(__MODULE__, :search_query, persist: false)

      Module.put_attribute(__MODULE__, :model, unquote(model))
      Module.put_attribute(__MODULE__, :index, unquote(index))
      Module.put_attribute(__MODULE__, :search, unquote(search))
      Module.put_attribute(__MODULE__, :index_query, unquote(index_query))
      Module.put_attribute(__MODULE__, :search_query, unquote(search_query))

      # IO.inspect(unquote(index_query), label: "index_query -------------------------------")
      # IO.inspect(unquote(search_query), label: "search_query -------------------------------")

      def list_resources(%QueryParams{search: search} = params)
          when is_nil(search) or search == "" do
        {query, params} =
          index_query()
          |> QueryParams.current(params)

        @model.list(query)
      end

      def list_resources(%QueryParams{} = params) do
        params.search
        |> like()
        |> Repo.all()
      end

      def model, do: @model
      def index_query, do: @index_query
      def search_query, do: @search_query

      def like(search_term) do
        Joint.LikeQuery.like(@model, @search, search_term, @search_query)
      end
    end
  end
end
