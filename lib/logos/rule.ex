defmodule Logos.Rule do
  @moduledoc """
  A collection of useful rules built from simple rules.
  """

  import Logos.Interface, only: [with_vars: 2, fork: 1]
  import Logos.Core, only: [equal: 2]

  def empty(l) do
    equal(l, [])
  end

  def prepend(h, t, res) do
    equal([h | t], res)
  end

  def head(l, h) do
    with_vars [t] do
      equal([h | t], l)
    end
  end

  def tail(l, t) do
    with_vars [h] do
      equal([h | t], l)
    end
  end

  def proper_list(l) do
    fork do
      [empty(l)]

      [
        with_vars [t] do
          [tail(l, t), proper_list(t)]
        end
      ]
    end
  end

  def member(x, l) do
    fork do
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
  end

  def concat(a, b, res) do
    fork do
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
end
