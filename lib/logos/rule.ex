defmodule Logos.Rule do
  @moduledoc """
  A collection of useful rules built from simple rules.
  """

  import Logos.Interface, only: [defrule: 2, with_vars: 2]
  import Logos.Core, only: [equal: 2]

  @doc """
  Rule expressing that list `l` is the empty list.

  ## Examples

    iex> use Logos
    iex> ask [x] do
    ...>   empty(x)
    ...> end
    ...> |> Enum.to_list()
    [[[]]]

    iex> use Logos
    iex> ask [x] do
    ...>   empty([])
    ...> end
    ...> |> Enum.to_list()
    [[:_0]]

  """
  defrule empty(l) do
    equal(l, [])
  end

  @doc """
  Rule expressing that when value `h` is prepended onto list `t` (i.e., `[h | t]`), the result is `res`.

  ## Examples

    iex> use Logos
    iex> ask [x] do
    ...>   prepend(1, x, [1, 2, 3])
    ...> end
    ...> |> Enum.to_list()
    [[[2, 3]]]
  """
  defrule prepend(h, t, res) do
    equal([h | t], res)
  end

  @doc """
  Rule expressing that `h` is the head of list `l`.

  ## Examples

    iex> use Logos
    iex> ask [x] do
    ...>   head(x, [1, 2, 3])
    ...> end
    ...> |> Enum.to_list()
    [[1]]
  """
  defrule head(h, l) do
    with_vars [t] do
      equal([h | t], l)
    end
  end

  @doc """
  Rule expressing that `t` is the tail of list `l`.

  ## Examples

    iex> use Logos
    iex> ask [x] do
    ...>   tail(x, [1, 2, 3])
    ...> end
    ...> |> Enum.to_list()
    [[[2, 3]]]
  """
  defrule tail(t, l) do
    with_vars [h] do
      equal([h | t], l)
    end
  end

  @doc """
  Rule expressing that list `l` is a _proper_ list.

  ## Examples

    iex> use Logos
    iex> ask [x] do
    ...>   proper_list([1, 2])
    ...> end
    ...> |> Enum.to_list()
    ...> [[:_0]]   # success

    iex> use Logos
    iex> ask [x] do
    ...>   proper_list([1 | 2])
    ...> end
    ...> |> Enum.to_list()
    ...> []   # failure
  """
  defrule proper_list(l) do
    empty(l)

    [
      with_vars [t] do
        [tail(t, l), proper_list(t)]
      end
    ]
  end

  @doc """
  Rule expressing that element `x` is contained in proper list `l`.

  ## Examples
    iex> use Logos
    iex> ask [x] do
    ...>   member(1, [x, 2, 3])
    ...> end
    ...> |> Enum.to_list()
    [[1]]
  """
  defrule member(x, l) do
    [
      head(x, l),
      with_vars [t] do
        [tail(t, l), proper_list(t)]
      end
    ]

    with_vars [t] do
      [tail(t, l), member(x, t)]
    end
  end

  @doc """
  Rule expressing that list `a` concatenated with list `b` yields the resulting list `res`.

  ## Examples
    iex> use Logos
    iex> ask [x] do
    ...>   concat([1, 2], x, [1, 2, 3, 4])
    ...> end
    ...> |> Enum.to_list()
    [[[3, 4]]]

    iex> use Logos
    iex> ask [x, y] do
    ...>   concat(x, y, [1, 2, 3])
    ...> end
    ...> |> Enum.to_list()
    [[[], [1, 2, 3]], [[1], [2, 3]], [[1, 2], [3]], [[1, 2, 3], []]]
  """
  defrule concat(a, b, res) do
    [empty(a), equal(b, res)]

    [
      with_vars [h, t, res_part] do
        [
          prepend(h, t, a),
          prepend(h, res_part, res),
          concat(t, b, res_part)
        ]
      end
    ]
  end
end
