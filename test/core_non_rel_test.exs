defmodule CoreNonRelTest do
  use ExUnit.Case, async: true
  doctest Logos.CoreNonRel

  use Logos

  test "inequalities, success" do
    result_gt = ask([x], do: [equal(x, 1), gt(10, x)]) |> Enum.to_list()
    result_lt = ask([x], do: [equal(x, 1), lt(x, 10)]) |> Enum.to_list()
    result_gte = ask([x], do: [equal(x, 1), gte(10, x)]) |> Enum.to_list()
    result_lte = ask([x], do: [equal(x, 1), lte(x, 1)]) |> Enum.to_list()
    result_neq = ask([x], do: [equal(x, 1), neq(x, 2)]) |> Enum.to_list()

    assert result_gt == [[1]]
    assert result_lt == [[1]]
    assert result_gte == [[1]]
    assert result_lte == [[1]]
    assert result_neq == [[1]]
  end

  test "inequalities, failure" do
    result_gt = ask([x], do: [equal(x, 1), gt(x, 10)]) |> Enum.to_list()
    result_neq = ask([x], do: [equal(x, 1), neq(x, 1)]) |> Enum.to_list()

    assert result_gt == []
    assert result_neq == []
  end

  test "binary addition" do
    result =
      ask [x, z] do
        with_vars [y] do
          all([
            any([equal(x, 1), equal(x, 2)]),
            equal(y, 3),
            add(x, y, z)
          ])
        end
      end
      |> Enum.to_list()

    assert result == [[1, 4], [2, 5]]
  end

  test "summation" do
    result =
      ask [x, z] do
        [equal(x, 2), sum([1, x, 3], z)]
      end
      |> Enum.to_list()

    assert result == [[2, 6]]
  end

  test "list length (count)" do
    result =
      ask [x, z] do
        count([1, x, 3], z)
      end
      |> Enum.to_list()

    assert result == [[:_0, 3]]
  end
end
