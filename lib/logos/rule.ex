defmodule Logos.Rule do
  @moduledoc """
  A collection of useful rules built from simple rules.
  """

  import Logos.Interface, only: [defrule: 2, with_vars: 2]
  import Logos.Core, only: [equal: 2]

  @doc """
  Rule expressing that list `l` is the empty list.
  """
  defrule empty(l) do
    equal(l, [])
  end

  @doc """
  Rule expressing that when value `h` is prepended onto list `t` (i.e., `[h | t]`), the result is `res`.
  """
  defrule prepend(h, t, res) do
    equal([h | t], res)
  end

  @doc """
  Rule expressing that `h` is the head of list `l`.
  """
  defrule head(h, l) do
    with_vars [t] do
      equal([h | t], l)
    end
  end

  @doc """
  Rule expressing that `t` is the tail of list `l`.
  """
  defrule tail(t, l) do
    with_vars [h] do
      equal([h | t], l)
    end
  end

  @doc """
  Rule expressing that list `l` is a _proper_ list.
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
