defmodule Joint.Orders.Address do
  use Ecto.Schema

  schema "addresses" do
    field(:street, :string)
    field(:city, :string)
    field(:state, :string)
    field(:zip, :string)

    timestamps(type: :utc_datetime)
  end
end

defmodule Joint.Orders.PaymentMethod do
  use Ecto.Schema

  schema "payment_methods" do
    field(:type, :string)
    field(:details, :map)

    timestamps(type: :utc_datetime)
  end
end

defmodule Joint.Orders.Product do
  use Ecto.Schema

  schema "products" do
    field(:name, :string)
    field(:sku, :string)
    field(:description, :string)
    field(:price, :decimal)

    timestamps(type: :utc_datetime)
  end
end

defmodule Joint.Orders.OrderItem do
  use Ecto.Schema

  schema "order_items" do
    field(:quantity, :integer)
    field(:price, :decimal)

    belongs_to(:order, Joint.Orders.Order)
    belongs_to(:product, Joint.Orders.Product)

    timestamps(type: :utc_datetime)
  end
end

defmodule Joint.Orders.Order do
  use Ecto.Schema

  schema "orders" do
    field(:date, :date)
    field(:status, :string, default: "pending")
    field(:total_price, :decimal)

    belongs_to(:shipping_address, Joint.Orders.Address)
    belongs_to(:billing_address, Joint.Orders.Address)
    belongs_to(:payment_method, Joint.Orders.PaymentMethod)
    has_many(:items, Joint.Orders.OrderItem)
    timestamps(type: :utc_datetime)
  end
end
