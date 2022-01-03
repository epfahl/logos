defmodule Logos.Core do
  @moduledoc """
  Primitive relations and helpers.
  """

  alias Logos.Unification, as: U
  alias Logos.Variable, as: V
  alias Logos.State, as: S
  alias Logos.DelayedList, as: D

  @doc """
  Return a goal that leaves the state unaltered and lifts it into a delayed list.
  """
  def success(), do: fn state -> D.single(state) end

  @doc """
  Return a goal that yields an empty stream.
  """
  def failure(), do: fn _state -> D.empty() end

  @doc """
  Return a goal that attempts to unify a pair of terms.
  """
  def equal(term1, term2) do
    fn %S{} = state ->
      case U.unify(state, term1, term2) do
        {:ok, s} -> D.single(s)
        {:error, _} -> D.empty()
      end
    end
  end

  @doc """
  Return a goal that represents disjunction over zero or more goals.
  """
  def any([_h | _t] = goals) do
    fn %S{} = state ->
      goals
      |> Enum.map(fn g -> delay(g).(state) end)
      |> D.interleave()
    end
  end

  def any([]), do: failure()

  @doc """
  Return a goal that represents conjunction over 0 or more goals.
  """
  def all([_h | _t] = goals) do
    Enum.reduce(goals, fn g, acc ->
      fn %S{} = state ->
        state |> delay(acc).() |> D.flat_map(g)
      end
    end)
  end

  def all([]), do: success()

  @doc """
  Return a goal that injects a new variable into a function-wrapped goal.
  """
  def with_var(var_to_goal) when is_function(var_to_goal, 1) do
    fn %S{count: c} = state ->
      state |> S.inc_count() |> var_to_goal.(V.new(c)).()
    end
  end

  @doc """
  Non-relational if-then-else goal.
  """
  def branch(g_if, g_then, g_else) do
    fn %S{} = state ->
      do_branch(state, g_if.(state), g_then, g_else)
    end
  end

  defp do_branch(_state, [_h | _t] = stream, g_then, _g_else), do: D.flat_map(stream, g_then)
  defp do_branch(state, [], _g_then, g_else), do: g_else.(state)

  defp do_branch(state, stream, g_then, g_else) when is_function(stream),
    do: fn -> do_branch(state, stream.(), g_then, g_else) end

  @doc """
  Return a goal that wraps the given goal in a thunk.
  """
  def delay(goal) do
    fn %S{} = state ->
      fn -> goal.(state) end
    end
  end

  @doc """
  Call a goal on an empty state and return the result as an Elixir Stream.
  """
  def call_on_empty(goal), do: goal.(S.empty()) |> D.to_stream()
end
