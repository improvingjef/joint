defmodule Joint.Web.Formatters do
  import Phoenix.HTML, only: [raw: 1]

  def loaded(%Ecto.Association.NotLoaded{}), do: false
  def loaded(nil), do: false
  def loaded(_), do: true
  def ok(socket), do: {:ok, socket}
  def no_reply(socket), do: {:noreply, socket}

  def pre(any), do: raw("<pre>#{to_string(any)}</pre>")
  def boolean("true"), do: true
  def boolean("false"), do: false
  def boolean(b) when is_boolean(b), do: b
  def boolean(_), do: false
  def tzdatetime(datetime), do: Calendar.strftime(datetime, "%y/%m/%d %H:%M %z")
  def date(date), do: Calendar.strftime(date, "%Y-%m-%d")
  def time(time), do: Calendar.strftime(time, "%I:%M %p")
  def percent(nil), do: "0%"
  def percent(%Decimal{} = value), do: "#{Decimal.mult(value, 100)}%"
  def percent(value), do: "#{value * 100}%"
  def pluralize(text), do: Inflex.inflect(text, 2)
  def capitalize(text), do: String.capitalize(text)
  def downcase(text), do: String.downcase(text)

  def count(list) when is_list(list), do: Enum.count(list)
  def count(_), do: "--"

  def email(%{email: email}), do: email
  def email(string) when is_binary(string), do: string
  def email(_), do: "--"

  def description(%{description: description}), do: description
  def description(string) when is_binary(string), do: string
  def description(_), do: "--"

  def name(nil), do: "--"
  def name(%{name: name}), do: name

  # def name(%Harmoni.Auth.User{} = user) do
  #   if is_nil(user.person) do
  #     user.email
  #   else
  #     user.person.name
  #   end
  # end

  def name(string) when is_binary(string), do: string

  # def type(type, name) do
  #   Harmoni.Type.for(type, name)
  # end

  # def type_id(type, name) do
  #   type(type, name).id
  # end
end
