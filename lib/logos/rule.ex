defmodule Logos.Rule do
  @moduledoc """
  A collection of useful rules built from simple rules.
  """

  import Logos.Interface, only: [defrule: 2, with_vars: 2]
  import Logos.Core, only: [equal: 2]

  defrule empty(l) do
    equal(l, [])
  end

  defrule prepend(h, t, res) do
    equal([h | t], res)
  end

  defrule head(l, h) do
    with_vars [t] do
      equal([h | t], l)
    end
  end

  defrule tail(l, t) do
    with_vars [h] do
      equal([h | t], l)
    end
  end

  defrule proper_list(l) do
    empty(l)

    [
      with_vars [t] do
        [tail(l, t), proper_list(t)]
      end
    ]
  end

  defrule member(x, l) do
    [
      head(l, x),
      with_vars [t] do
        [tail(l, t), proper_list(t)]
      end
    ]

    [
      with_vars [t] do
        [tail(l, t), member(x, t)]
      end
    ]
  end

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
