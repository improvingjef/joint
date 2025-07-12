defmodule Joint.Repo.Migrations.AddOrderTables do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :street, :string
      add :city, :string
      add :state, :string
      add :zip, :string
    end

    create table(:payment_methods) do
      add :type, :string
      add :details, :map
    end
    create table(:orders) do
      add :date, :date
      add :status, :string, default: "pending"
      add :total_price, :decimal, precision: 10, scale: 2
      add :shipping_address_id, references(:addresses, on_delete: :delete_all)
      add :billing_address_id, references(:addresses, on_delete: :delete_all)
      add :payment_method_id, references(:payment_methods, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create table(:products) do
      add :name, :string
      add :sku, :string
      add :description, :text
      add :price, :decimal, precision: 10, scale: 2

      timestamps(type: :utc_datetime)
    end

    create table(:order_items) do
      add :order_id, references(:orders, on_delete: :delete_all)
      add :product_id, references(:products, on_delete: :delete_all)
      add :quantity, :integer
      add :price, :decimal, precision: 10, scale: 2

      timestamps(type: :utc_datetime)
    end
  end
end
