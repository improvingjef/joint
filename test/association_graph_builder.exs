defmodule Joint.AssociationGraphBuilderTest do
  use Joint.DataCase
  alias Joint.AssociationGraphBuilder
  alias Joint.Orders.Order

  # field :batch, :integer
  # field :scheduled_date, :date
  # field :green_weight, :decimal
  # field :charge_temperature, :decimal
  # field :density, :decimal
  # field :bulk_density, :decimal
  # field :moisture_content, :decimal
  # field :water_activity, :decimal
  # field :hardness, :decimal
  # belongs_to :weight_unit, SystemUnit, foreign_key: :weight_unit_id
  # belongs_to :temperature_unit, SystemUnit, foreign_key: :temperature_unit_id
  # belongs_to :user, User
  # belongs_to :roaster, Roaster
  # belongs_to :offering, Offering

  # search: [:batch, :scheduled_date,
  # roaster: [:name,
  #   model: [:name, make: :name]],
  # offering: [:name, :description, :sku, :upc,
  #   # type: [:type, :name],
  #   # supplier: :name,
  #   # category: :name
  #   ],
  # user: [:email,
  #   person: [:name]]
  # ],

  describe "AssociationGraphBuilder" do
    test "attributes only returns empty list" do
      assert [] == AssociationGraphBuilder.walk(Order, [:date, :status])
    end

    test "attributes plus one assoc returns single element list with assoc" do
      assert [:shipping_address] ==
               AssociationGraphBuilder.walk(Order, [:date, :status, :shipping_address])
    end

    test "assoc with nested attributes returns only assoc" do
      assert [:shipping_address] ==
               AssociationGraphBuilder.walk(Order, [:date, :status, shipping_address: [:city]])
    end

    test "assoc with deeply nested assoc returns only assoc" do
      assert [{:items, [:product]}] ==
               AssociationGraphBuilder.walk(Order, [
                 :date,
                 :status,
                 items: [product: [:name, :sku]]
               ])
    end

    test "assoc with deeply nested assoc returns only assoc - part 2" do
      assert [items: [:product]] ==
               AssociationGraphBuilder.walk(
                 Order,
                 [
                   :date,
                   :status,
                   items: [product: [:name, :sku]]
                 ]
               )
    end

    # test "assoc with even more levels nested assoc returns only assoc" do
    #   assert [{:roaster, [model: [:make]]}, {:offering, [:type, :supplier, :category]}] ==
    #            AssociationGraphBuilder.walk(
    #              Order,
    #              [
    #                :scheduled_date,
    #                :batch,
    #                roaster: [:name, model: [:name, make: :name]],
    #                offering: [
    #                  :name,
    #                  :description,
    #                  :sku,
    #                  :upc,
    #                  type: [:type, :name],
    #                  supplier: :name,
    #                  category: :name
    #                ]
    #              ]
    #            )
    # end

    test "the whole enchilada" do
      assert [
               :payment_method,
               :shipping_address,
               :billing_address,
               items: [:product]
             ] ==
               AssociationGraphBuilder.walk(
                 Order,
                 [
                   :date,
                   :status,
                   :total_price,
                   payment_method: [:name, :type],
                   shipping_address: [:street, :city, :state, :zip],
                   billing_address: [:street, :city, :state, :zip],
                   items: [:quantity, :price, {:product, [:name, :sku, :description, :price]}],
                   user: [:email, person: [:name]]
                 ]
               )
    end
  end
end
