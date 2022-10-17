defmodule Logos.Unification do
  @moduledoc """
  Defines `unify`, the core algorithm for manipulating bindings of logical variables.

  ## Notes
  - Even if only for documentation, it would be beneficial to have a `term` type, a union
    of union of atomic value (number, string, atom), variable, and list of terms
    (recursive).

    @type logos_atom() :: number() | atom() | String.t() | []
    @type logos_term() :: latom() | [latom()]


  ## Test `unify`
  - atom, variable, and list terms
  - reflexivity, commutativity, transativity, associativity
  - when `occurs?` violated
  - Peter Norvig's test case (look it up)
  """

  alias Logos.Variable, as: V
  alias Logos.State, as: S

  @doc """
  Attempt to unify a pair of terms in the given state. This returns either
  `{:ok, <updated state>}` or `{:error, message}` if the terms cannot be unified.
  """
  def unify(%S{} = state, term1, term2) do
    term1_walked = S.walk(state, term1)
    term2_walked = S.walk(state, term2)
    do_unify(state, term1_walked, term2_walked)
  end

  defp do_unify(state, term1, term2) when term1 == term2, do: {:ok, state}
  defp do_unify(state, %V{} = var, term), do: occurs_or_extend(state, var, term)
  defp do_unify(state, term, %V{} = var), do: occurs_or_extend(state, var, term)

  defp do_unify(state, [h1 | t1], [h2 | t2]) do
    case unify(state, h1, h2) do
      {:ok, s} -> unify(s, t1, t2)
      :error -> :error
    end
  end

  defp do_unify(_state, _term1, _term2), do: :error

  @doc """
  Determine if variable `var` occurs in `term`, which indicates a recursive
  a cycle in the implied graph of associations.
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

  defp occurs_or_extend(state, var, term) do
    if occurs?(state, var, term) do
      :error
    else
      {:ok, S.extend(state, var, term)}
    end
  end
end
