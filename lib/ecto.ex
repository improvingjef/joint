defmodule Joint.Ecto do
  def join_arguments(arguments) do
    Enum.map_join(arguments, ", ", fn _ -> "? " end)
  end

  defmacro string(field) do
    quote do
      fragment("CAST(? as text)", unquote(field))
    end
  end

  defmacro normalize_proper_name(name) do
    frag = "initcap(lower(btrim(?)))"

    quote do
      fragment(unquote(frag), unquote(name))
    end
  end

  defmacro concat(arguments)
           when is_list(arguments) do
    frag = "concat(#{join_arguments(arguments)})"

    quote do
      fragment(unquote(frag), unquote_splicing(arguments))
    end
  end

  defmacro concat(separator, arguments)
           when is_list(arguments) do
    frag = "concat_ws('#{separator}', #{join_arguments(arguments)})"

    quote do
      fragment(unquote(frag), unquote_splicing(arguments))
    end
  end

  defmacro start_of_year(date) do
    quote do
      fragment("make_date((extract(year from ?)::integer), 1, 1)", unquote(date))
    end
  end

  defmacro start_of_month(date) do
    quote do
      fragment(
        "make_date(extract(year from ?)::integer, extract(month from ?)::integer, 1)",
        unquote(date),
        unquote(date)
      )
    end
  end

  defmacro start_of_week(date) do
    quote do
      fragment("date_trunc('week', ?::timestamp)::date", unquote(date))
    end
  end

  defmacro date(year, month, day)
           when is_integer(year) and is_integer(month) and is_integer(day) do
    quote do
      fragment("make_date(?, ?, ?)", unquote(year), unquote(month), unquote(day))
    end
  end

  defmacro date(datetime) do
    quote do
      fragment("date(?)", unquote(datetime))
    end
  end

  defmacro to_int(number) do
    quote do
      fragment("?::integer", unquote(number))
    end
  end

  defmacro numbers_only(string) do
    quote do
      fragment("regexp_replace(?, '[^0-9]+', '', 'g')", unquote(string))
    end
  end

  defmacro lower(string) do
    quote do
      fragment("lower(btrim(?))", unquote(string))
    end
  end

  defmacro coalesce(arguments)
           when is_list(arguments) do
    frag = "coalesce(#{join_arguments(arguments)})"

    quote do
      fragment(unquote(frag), unquote_splicing(arguments))
    end
  end

  defmacro coalesce(a, b) do
    quote do
      fragment("coalesce(?, ?)", unquote(a), unquote(b))
    end
  end

  defmacro week(date) do
    quote do
      fragment("extract(week from ?)::integer", unquote(date))
    end
  end

  defmacro month(date) do
    quote do
      fragment("extract(month from ?)::integer", unquote(date))
    end
  end

  defmacro year(date) do
    quote do
      fragment("extract(year from ?)::integer", unquote(date))
    end
  end
end
