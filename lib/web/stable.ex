defmodule Joint.Web.Stable do
  import Joint.Web.Formatters, only: [date: 1, time: 1]

  def sort_icon(order_by, field, direction) do
    if order_by == field do
      case direction do
        :asc -> "hero-arrow-long-up"
        "asc" -> "hero-arrow-long-up"
        :desc -> "hero-arrow-long-down"
        "desc" -> "hero-arrow-long-down"
        _ -> "hero-chevron-up-down"
      end
    else
      "hero-chevron-up-down"
    end
  end

  def normalize(cols) when is_list(cols) do
    Enum.map(cols, &normalize/1)
  end

  def normalize(col) do
    col
    |> Map.put_new(:header, header_text(col[:field]))
    |> Map.put_new(:sortable, false)
    |> Map.put_new(:align, "text-start")
    |> Map.put_new(:class, "")
    |> Map.put_new(:format, &format/1)
  end

  def header_text(nil), do: "--"

  def header_text(field) when is_atom(field) do
    Phoenix.Naming.humanize(field)
  end

  def header_text({assoc, field}) do
    "#{Phoenix.Naming.humanize(assoc)} #{header_text(field)}"
  end

  def header_text(list) when is_list(list) do
    Enum.map_join(list, ", ", &header_text/1)
  end

  def format(%Date{} = date), do: date(date)
  def format(%Time{} = time), do: time(time)

  def format(%DateTime{} = datetime) do
    Phoenix.HTML.raw(
      "<time datetime='#{datetime}' id='#{Ecto.UUID.generate()}' phx-hook='LocalTime'></time>"
    )
  end

  def format(%NaiveDateTime{} = datetime) do
    "#{date(datetime)} #{time(datetime)}"
  end

  def format(b) when is_boolean(b), do: yes_no?(b)
  def format(any), do: to_string(any)

  def yes_no?(b) when is_boolean(b), do: if(b, do: "Yes", else: "No")

  def direction(a, b, direction) do
    if a == b do
      opposite(direction)
    else
      :asc
    end
  end

  def direction(opposite?, direction) do
    if opposite?, do: opposite(direction), else: :asc
  end

  def opposite(:asc), do: :desc
  def opposite(:desc), do: :asc

  # stream support
  def value({_, row}, col), do: value(row, col)

  def value(row, col) do
    row
    |> get_value(col.field)
    |> col.format.()
  end

  def get_value(row, {assoc, field}) when is_atom(field) do
    row
    |> Map.get(assoc)
    |> then(&if is_nil(&1), do: %{}, else: &1)
    |> get_value(field)
  end

  def get_value(row, field) when is_atom(field) do
    Map.get(row, field, "--")
  end

  def to_field_string(a) when is_atom(a), do: a
  def to_field_string({a, b}), do: "#{a}.#{to_field_string(b)}"

  def to_field_string(list) when is_list(list) do
    Enum.map_join(list, ",", &to_field_string/1)
  end
end
