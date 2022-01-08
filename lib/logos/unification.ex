defmodule Logos.Unification do
  @moduledoc """
  Defines `unify`, the core algorithm for manipulating bindings of logical variables.
  """

  alias Logos.Variable, as: V
  alias Logos.State, as: S

  # @doc """
  # Retrieve the value associated with a term by traversing the relationships between variables in the state, and stopping when the value is a list or constant.
  # """
  # def walk(%S{} = state, term) do
  #   case S.fetch(state, term) do
  #     {:ok, t} -> walk(state, t)
  #     :error -> term
  #   end
  # end

  @doc """
  Attempt to unify a pair of terms in the given state. This returns either `{:ok, <updated state>}` or `{:error, message}` if the terms cannot be unified.
  """
  def unify(%S{} = state, term1, term2) do
    wterm1 = S.walk(state, term1)
    wterm2 = S.walk(state, term2)
    do_unify(state, wterm1, wterm2)
  end

  defp do_unify(state, term1, term2) when term1 == term2, do: {:ok, state}
  defp do_unify(state, %V{} = term1, term2), do: S.extend_sub(state, term1, term2)
  defp do_unify(state, term1, %V{} = term2), do: S.extend_sub(state, term2, term1)

  defp do_unify(state, [h1 | t1], [h2 | t2]) do
    case unify(state, h1, h2) do
      {:ok, s} -> unify(s, t1, t2)
      {:error, m} -> {:error, m}
    end
  end

  defp do_unify(_state, _term1, _term2), do: {:error, "unification failed"}
end
