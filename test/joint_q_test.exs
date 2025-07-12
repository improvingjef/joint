defmodule Joint.QTest do
  use Joint.DataCase
  use Joint.Q

  describe "Q" do
    test "will generate a basic query from a schema module" do
      expected = from(r in Joint.Orders.Order, as: :order)
      actual = q(Joint.Orders.Order, [])

      refute is_nil(actual)
      refute is_nil(actual.from)
      refute is_nil(expected)
      refute is_nil(expected.from)
      refute expected.from.line == actual.from.line
      actual = %{actual | from: %{actual.from | line: expected.from.line}}
      assert actual == expected
    end

    test "will join a belongs_to association" do
      expected =
        from(o in Joint.Orders.Order,
          as: :order,
          join: a in assoc(o, :shipping_address),
          as: :shipping_address,
          preload: [shipping_address: a]
        )

      actual = q(Joint.Orders.Order, [:shipping_address])

      refute is_nil(actual)
      refute is_nil(actual.from)
      refute is_nil(expected)
      refute is_nil(expected.from)
      refute expected.from.line == actual.from.line
      actual = %{actual | from: %{actual.from | line: expected.from.line}}

      actual_join = actual.joins |> List.first()
      expected_join = expected.joins |> List.first()

      actual_join = %{
        actual_join
        | line: expected_join.line,
          on: %{actual_join.on | line: expected_join.on.line}
      }

      actual = %{actual | joins: [actual_join]}

      assert actual == expected
    end

    test "will join a has_many association" do
      expected =
        from(o in Joint.Orders.Order,
          as: :order,
          join: i in assoc(o, :items),
          as: :items,
          preload: [items: i]
        )

      actual = q(Joint.Orders.Order, [:items])

      refute is_nil(actual)
      refute is_nil(actual.from)
      refute is_nil(expected)
      refute is_nil(expected.from)
      refute expected.from.line == actual.from.line
      actual = %{actual | from: %{actual.from | line: expected.from.line}}

      actual_join = actual.joins |> List.first()
      expected_join = expected.joins |> List.first()

      actual_join = %{
        actual_join
        | line: expected_join.line,
          on: %{actual_join.on | line: expected_join.on.line}
      }

      actual = %{actual | joins: [actual_join]}

      assert actual == expected
    end

    test "will left_join a has_many association" do
      expected =
        from(o in Joint.Orders.Order,
          as: :order,
          left_join: i in assoc(o, :items),
          as: :items,
          preload: [items: i]
        )

      actual = q(Joint.Orders.Order, left_join: [:items])

      refute is_nil(actual)
      refute is_nil(actual.from)
      refute is_nil(expected)
      refute is_nil(expected.from)
      refute expected.from.line == actual.from.line
      actual = %{actual | from: %{actual.from | line: expected.from.line}}

      actual_join = actual.joins |> List.first()
      expected_join = expected.joins |> List.first()

      actual_join = %{
        actual_join
        | line: expected_join.line,
          on: %{actual_join.on | line: expected_join.on.line}
      }

      actual = %{actual | joins: [actual_join]}

      assert actual == expected
    end
  end
end
