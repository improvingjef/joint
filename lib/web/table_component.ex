defmodule Joint.Web.TableComponent do
  use Phoenix.Component
  import Joint.Web.Stable

  def row({_, row}), do: row
  def row(row), do: row

  @doc ~S"""
  Renders a table with default styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr(:id, :string, required: true)
  attr(:row_click, :any, default: nil)
  attr(:rows, :list, required: true)
  attr(:break, :string, default: "md")
  attr(:card, :string, required: false)
  attr(:grid, :string, required: false)
  attr(:sort, :any, default: "")
  attr(:order_by, :atom)
  attr(:uri_path, :string, default: "")
  attr(:direction, :atom, values: [:asc, :desc], default: :asc)

  slot :col, required: true do
    attr(:field, :atom)
    attr(:sortable, :boolean)
    attr(:edit, :string)
    attr(:header, :string)
    attr(:class, :string)
    attr(:align, :string, values: ~w[text-start text-center text-end text-justify])
    attr(:format, :any)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def stable(assigns) do
    normalized = normalize(assigns.col)

    assigns =
      assigns
      |> assign(:col, normalized)
      |> Map.put_new(:class, "")
      |> Map.put_new(:uri, ".")

    ~H"""
    <div class="lg:border border-white/40 rounded-lg">
      <table id={@id} role="table" class="card-table">
        <thead role="rowgroup">
          <tr role="row">
            <th :for={col <- @col} role="columnheader" class={[col.align, col.class]}>
              <span :if={not col.sortable}><%= col.header %></span>
              <.link
                :if={col.sortable}
                class="flex flex-row items-center gap-1"
                patch={
                  # IO.inspect(
                  # ,
                  "#{@uri_path}?order_by=#{to_field_string(col.field)}&direction=#{direction(@order_by, col[:field], @direction)}"
                  #  label: "URL ----------------------------------"
                  # )
                }
              >
                <span><%= col.header %></span>
                <span class={[sort_icon(@order_by, col[:field], @direction), "w-4 h-4"]} />
              </.link>
            </th>
            <th :if={@action != []} role="columnheader">
              <span class="sr-only"><%= "Actions" %></span>
            </th>
          </tr>
        </thead>
        <tbody id="table-items" role="rowgroup" phx-update="stream">
          <tr id="no-items" class="no-items hidden">
            <td class="text-center py-4" colspan={Enum.count(@col) + 1}>No items to display.</td>
          </tr>
          <tr :for={row <- @rows} role="row" id={"#{@id}-#{Phoenix.Param.to_param(row(row))}"}>
            <!-- The data-heading is used in card mode to provide a header for the data item -->
            <td
              :for={{col, _i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              role="cell"
              data-heading={col[:header]}
              class={[col.class, col.align]}
            >
              <div>
                <span :if={col[:inner_block]}><%= render_slot(col, row) %></span>
                <!-- this phx-value-id value assumes the row has an id. Maybe Phoenix.Param is better? -->
                <form :if={is_nil(col[:inner_block]) and not is_nil(col[:edit])} phx-change={col[:edit]} phx-value-id={elem(row, 1).id}>
                  <input class="stable-inline-edit" name="value" value={value(row, col)}>`
                </form>
                <span :if={is_nil(col[:inner_block]) and is_nil(col[:edit])}><%= value(row, col) %></span>
              </div>
            </td>
            <td :if={@action != []} role="cell">
              <div>
                <span :for={action <- @action}>
                  <%= render_slot(action, row) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a stable component using a Joint.Web.Table module and a list of Ecto schema records.

  ## Attributes
    - `id`: A unique identifier for the table (required).
    - `table_module`: A module using Joint.Web.Table (e.g., RoastTable, BatchTable) (required).
    - `records`: A list of Ecto schema structs matching the table's resource (required).
    - `order_by`: The field being sorted (atom, tuple, or list) (optional).
    - `direction`: The sort direction (:asc or :desc) (optional, defaults to :asc).
    - `uri_path`: The base URI path for sorting links (optional, defaults to "").
    - `row_click`: A function to handle row clicks (optional).

  ## Example
      <.table
        id="roast-table"
        table_module={RoastTable}
        records={@roasts}
        order_by={@order_by}
        direction={@direction}
      />
  """

  attr(:id, :string, required: true)
  attr(:table_module, :atom, required: true)
  attr(:records, :list, required: true)
  attr(:order_by, :any, default: nil)
  attr(:direction, :atom, values: [:asc, :desc], default: :asc)
  attr(:uri_path, :string, default: "")
  attr(:row_click, :any, default: nil)

  def table(assigns) do
    assigns = assign(assigns, :columns, normalize(assigns.table_module.columns()))

    ~H"""
    <.stable
      id={@id}
      rows={@records}
      order_by={@order_by}
      direction={@direction}
      uri_path={@uri_path}
      row_click={@row_click}
    >
      <:col
        :for={col <- @columns}
        field={col.field}
        sortable={col.sortable}
        header={col.header}
        class={col.class}
        align={col.align}
        format={col.format}
      >
        <%= if is_nil(col.value), do: nil, else: col.value.() %>
      </:col>
    </.stable>
    """
  end
end
