defmodule InterfaceTest do
  use ExUnit.Case, async: true
  doctest Logos.Interface

  use Logos

  test "implicit disjunction over conjunctions" do
    result =
      ask [x, y, z] do
        [equal(x, y), equal(y, 1)]

        [equal(x, y), equal(y, [1, z]), equal(z, 2)]
      end
      |> Enum.to_list()

    assert result == [[1, 1, :_0], [[1, 2], [1, 2], 2]]
  end

  test "implicit disjunction with intermediate vars" do
    result =
      ask [x] do
        equal(x, 1)

        with_vars [y, z] do
          [equal(x, y), equal(y, z), equal(z, 2)]
        end
      end
      |> Enum.to_list()

    assert result == [[1], [2]]
  end

  test "non-relational choice" do
    result =
      ask [z] do
        with_vars [x, y] do
          [
            equal(x, 2),
            choice do
              equal(x, 1) -> [equal(z, y), equal(y, "no")]
              equal(x, 2) -> [equal(z, y), equal(y, "yes")]
            end
          ]
        end
      end
      |> Enum.to_list()

    assert result == [["yes"]]
  end

  test "negation as failure" do
    result =
      ask [x] do
        [
          equal(x, 1),
          neg do
            equal(x, 2)
          end
        ]
      end
      |> Enum.to_list()

    assert result == [[1]]
  end
end
