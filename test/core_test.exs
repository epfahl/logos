defmodule CoreTest do
  use ExUnit.Case, async: true
  doctest Logos.Core

  import Logos.Core
  import Logos.Interface, only: [ask: 2]

  # TODO: test `Core.with_var`

  test "simple substitution" do
    result = ask([x], do: equal(x, 1)) |> Enum.to_list()
    assert result == [[1]]
  end

  test "failed equality" do
    result = ask([x], do: equal(1, 2)) |> Enum.to_list()
    assert result == []
  end

  test "non-grounded result" do
    result = ask([x, y], do: equal(x, y)) |> Enum.to_list()
    assert result == [[:_0, :_0]]
  end

  test "list pattern matching" do
    result = ask([x, y], do: equal([x, 2], [1, y])) |> Enum.to_list()
    assert result == [[1, 2]]
  end

  test "nested list pattern matching" do
    result = ask([x, y], do: equal([x, [1, 2]], [1, [1, y]])) |> Enum.to_list()
    assert result == [[1, 2]]
  end

  test "binary conjunction and equality transitivity" do
    result = ask([x, y], do: both(equal(x, y), equal(y, 1))) |> Enum.to_list()
    assert result == [[1, 1]]
  end

  test "binary conjunction and equality associativity" do
    result =
      ask [x, y, z] do
        both(
          both(equal(x, y), both(equal(y, z), equal(z, 1))),
          both(both(equal(x, y), equal(y, z)), equal(z, 1))
        )
      end
      |> Enum.to_list()

    assert result == [[1, 1, 1]]
  end

  test "binary disjunction" do
    result = ask([x], do: either(equal(x, 1), equal(x, 2))) |> Enum.to_list()
    assert result == [[1], [2]]
  end

  test "emtpy multi-arity conjunction" do
    result = ask([x], do: all([])) |> Enum.to_list()
    assert result == [[:_0]]
  end

  test "emtpy multi-arity disjunction" do
    result = ask([x], do: any([])) |> Enum.to_list()
    assert result == []
  end

  test "complex multi-arity expression" do
    result =
      ask [x, y, z] do
        any([
          all([equal(x, y), equal(y, z), equal(z, 1)]),
          all([equal(x, [1, y]), equal(y, z), equal(z, [2, 3])])
        ])
      end
      |> Enum.to_list()

    assert result == [[1, 1, 1], [[1, [2, 3]], [2, 3], [2, 3]]]
  end

  test "occurs check failure" do
    result = ask([x], do: equal(x, [1, x])) |> Enum.to_list()
    assert result == []
  end

  test "norvig occurs unification test" do
    result =
      ask [x, y] do
        equal([1, x, y, 2], [1, y, x, x])
      end
      |> Enum.to_list()

    assert result == [[2, 2]]
  end
end
