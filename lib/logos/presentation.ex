defmodule Logos.Presentation do
  @moduledoc """
  Functions for creating the presentation of the results of an executed logic program.
  """

  alias Logos.Variable, as: V
  alias Logos.State, as: S

  # @doc """
  # Deeply traverse the state by walking both variables and lists that may contain variables.

  # Notes
  # * May move to a more general place, since this has use beyond presentation, I think.
  # """
  # def walk_deep(%S{} = state, term) do
  #   wterm = U.walk(state, term)
  #   do_walk_deep(state, wterm)
  # end

  # defp do_walk_deep(state, [h | t]), do: [walk_deep(state, h) | walk_deep(state, t)]
  # defp do_walk_deep(_state, term), do: term

  @doc """
  Present a term by finding its most grounded value in a state and, if the value is a variable, creating an abstract representation.
  """
  def present(term) do
    fn %S{} = state ->
      wterm = S.walk_deep(state, term)

      S.empty()
      |> create_var_sub(wterm)
      |> S.walk_deep(wterm)
    end
  end

  @doc """
  Create the presented variable name substitution for a term.
  """
  def create_var_sub(%S{} = state, term), do: do_create_var_sub(state, S.walk(state, term))

  defp do_create_var_sub(%S{count: c} = state, %V{} = v) do
    rvar = present_var(c)
    state = S.put_sub(state, v, rvar)
    %{state | count: c + 1}
  end

  defp do_create_var_sub(state, [h | t]) do
    state |> create_var_sub(h) |> create_var_sub(t)
  end

  defp do_create_var_sub(state, _term), do: state

  defp present_var(n), do: :"_#{n}"
end
