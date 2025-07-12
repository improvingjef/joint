defmodule Joint.Filter do
  def filter(enumerable, q, _map) when is_nil(q) or q == "", do: enumerable

  def filter(enumerable, q, map) when is_binary(q), do: filter(enumerable, String.split(q), map)

  def filter(enumerable, search_parameters, map) when is_list(search_parameters) do
    if Enum.count(search_parameters) > 0 do
      to_exclude =
        Enum.filter(search_parameters, fn s -> String.starts_with?(s, "-") == true end)
        |> Enum.map(fn s -> String.slice(s, 1..(String.length(s) - 1)) end)

      to_include =
        Enum.filter(search_parameters, fn s -> String.starts_with?(s, "-") == false end)

      enumerable
      |> exclude(to_exclude, map)
      |> include(to_include, map)
    else
      enumerable
    end
  end

  defp exclude(candidates, exclusions, map)
       when is_list(candidates) and is_list(exclusions) do
    Enum.reject(candidates, fn candidate -> exclude(candidate, exclusions, map) end)
  end

  defp exclude(candidate, exclusions, map) when is_list(exclusions) do
    Enum.any?(map.(candidate), fn prop -> exclude(prop, exclusions) end)
  end

  defp exclude(prop, exclusions) when is_list(exclusions) do
    Enum.any?(exclusions, fn exclusion -> exclude(prop, exclusion) end)
  end

  defp exclude(prop, exclusion) when is_binary(prop) and is_binary(exclusion) do
    prop != nil && String.contains?(String.downcase(prop), String.downcase(exclusion))
  end

  defp include(candidates, parameters, map)
       when is_list(candidates) and is_list(parameters) do
    Enum.filter(candidates, fn c -> include(c, parameters, map) end)
  end

  defp include(candidate, parameters, map) when is_list(parameters) do
    Enum.all?(parameters, fn parameter -> include(candidate, parameter, map) end)
  end

  defp include(candidate, parameter, map) do
    Enum.any?(
      map.(candidate),
      &(not is_nil(&1) and String.contains?(String.downcase(&1), String.downcase(parameter)))
    )
  end
end
