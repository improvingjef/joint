defmodule Joint.LikeQueryTest do
  use Joint.DataCase
  alias Joint.LikeQuery

  describe "LikeQuery" do
    test "and_clause with literal" do
      assert LikeQuery.and_clause(true, 1) == 1
      assert LikeQuery.and_clause(2, true) == 2
    end

    test "or_clause with literal" do
      assert LikeQuery.or_clause(false, 1) == 1
      assert LikeQuery.or_clause(2, false) == 2
    end

    test "like" do
      query =
        LikeQuery.like(Joint.Orders.Product, [:sku, :name, :description, :price], "succeed -fail")

      assert not is_nil(query)
    end

    test "complicated joins" do
      IO.inspect("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")

      query =
        LikeQuery.like(
          Joint.Orders.Order,
          [
            :date,
            shipping_address: [:street, :city, :state, :zip],
            billing_address: [:street, :city, :state, :zip],
            items: [:quantity, :price, product: [:name, :sku, :description, :price]]
          ],
          "betsy"
        )
        |> dbg()

      assert not is_nil(query)
    end
  end
end
