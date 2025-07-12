defmodule Joint.Mapper do
  def map(struct, specification) do
    Enum.reduce(specification, {struct, %{}}, &do_map/2)
  end

  def do_map(atom, acc) when is_atom(atom) do
    do_map({atom, atom}, acc)
  end

  def do_map({key, value}, {source, acc}) when is_atom(key) and is_atom(value) do
    value = Map.get(source, value)
    {source, Map.put(acc, key, value)}
  end

  def do_map({key, list}, {source, acc}) when is_list(list) do
    {source, Map.put(acc, key, Enum.map(list, &do_map(&1, {source, acc})))}
  end
end
