defmodule Logos.DelayedEval do
  @moduledoc """
  Implement creation and evaluation of _promises_ following conventions similar to
  [Racket](https://docs.racket-lang.org/reference/Delayed_Evaluation.html).
  """

  defguard is_promise(x) when is_function(x, 0)

  @doc """
  Return a promise for the value of `expr`, a single line expression. When the promise
  is _forced_, the value of `expr` is returned.
  """
  defmacro delay(expr) do
    quote do
      fn ->
        unquote(expr)
      end
    end
  end

  @doc """
  Evaluate the body of a promise. If `x` is not a promise, its value is returned.
  """
  def force(x) when is_promise(x), do: x.()
  def force(x), do: x
end
