defmodule Logos.Unification do
  @moduledoc """
  Defines `unify`, the core algorithm for manipulating bindings of logical variables.
  """

  alias Logos.Variable, as: V
  alias Logos.State, as: S

  @doc """
  Attempt to unify a pair of terms in the given state. This returns either `{:ok, <updated state>}` or `{:error, message}` if the terms cannot be unified.
  """
  def unify(%S{} = state, term1, term2) do
    term1_walked = S.walk(state, term1)
    term2_walked = S.walk(state, term2)
    do_unify(state, term1_walked, term2_walked)
  end

  defp do_unify(state, term1, term2) when term1 == term2, do: {:ok, state}
  defp do_unify(state, %V{} = term1, term2), do: {:ok, S.put_sub(state, term1, term2)}
  defp do_unify(state, term1, %V{} = term2), do: {:ok, S.put_sub(state, term2, term1)}

  defp do_unify(state, [h1 | t1], [h2 | t2]) do
    case unify(state, h1, h2) do
      {:ok, s} -> unify(s, t1, t2)
      :error -> :error
    end
  end

  defp do_unify(_state, _term1, _term2), do: :error

  @doc """
  Determine if variable `var` occurs in `term`, which indicates a recursive relationship--a cycle in the implied graph of associations.
  """
  def occurs?(%S{} = state, %V{} = var, term) do
    term_walked = S.walk(state, term)
    do_occurs(state, var, term_walked)
  end

  defp do_occurs(_state, var, %V{} = term), do: var == term

  defp do_occurs(state, var, [h | t]) do
    Kernel.or(
      occurs?(state, var, h),
      occurs?(state, var, t)
    )
  end

  defp do_occurs(_state, _key, _term), do: false
end
