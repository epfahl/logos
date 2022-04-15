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
  Return a goal that yields an empty delayed list.
  """
  def failure(), do: fn _state -> D.empty() end

  @doc """
  Return a goal that attempts to unify a pair of terms.

  ## Examples

    iex> import Logos.Core
    iex> alias Logos.Variable, as: V
    iex> equal(1, 1) |> call_on_empty() |> Enum.to_list()
    [%Logos.State{count: 0, sub: %{}}]
    iex> equal(1, 2) |> call_on_empty() |> Enum.to_list()
    []
    iex> x = V.new(:x)
    iex> equal(x, 1) |> call_on_empty() |> Enum.to_list()
    [%Logos.State{count: 0, sub: %{%Logos.Variable{id: :x} => 1}}]
  """
  def equal(term1, term2) do
    fn %S{} = state ->
      case U.unify(state, term1, term2) do
        {:ok, s} -> D.single(s)
        :error -> D.empty()
      end
    end
  end

  @doc """
  Return a goal that represents the disjunction of a pair of goals. If the goal is
  successful then _either_ input goal, but at least one, is successful.

  ## Examples

    iex> import Logos.Core
    iex> alias Logos.Variable, as: V
    iex> x = V.new(:x)
    iex> either(equal(x, 1), equal(x, 2)) |> call_on_empty() |> Enum.to_list()
    [
      %Logos.State{count: 0, sub: %{%Logos.Variable{id: :x} => 1}},
      %Logos.State{count: 0, sub: %{%Logos.Variable{id: :x} => 2}}
    ]
  """
  def either(goal1, goal2) do
    fn %S{} = state ->
      D.mplus(
        delay(state, goal1),
        delay(state, goal2)
      )
    end
  end

  @doc """
  Return a goal that represents the conjunction of a pair of goals. If the goal is
  successful then _both_ input goals must be successful.

  ## Examples

    iex> import Logos.Core
    iex> alias Logos.Variable, as: V
    iex> x = V.new(:x)
    iex> both(equal(x, 1), equal(2, 2)) |> call_on_empty() |> Enum.to_list()
    [%Logos.State{count: 0, sub: %{%Logos.Variable{id: :x} => 1}}]
    iex> both(equal(x, 1), equal(x, 2)) |> call_on_empty() |> Enum.to_list()
    []
  """
  def both(goal1, goal2) do
    fn %S{} = state ->
      D.bind(delay(state, goal1), goal2)
    end
  end

  @doc """
  Return a goal that represents disjunction over zero or more goals.
  """
  def any([_h | _t] = goals) do
    fn %S{} = state ->
      goals
      |> Enum.map(fn g -> delay_goal(g).(state) end)
      |> D.interleave()
    end
  end

  def any([]), do: failure()

  @doc """
  Return a goal that represents conjunction over zero or more goals.
  """
  def all([_h | _t] = goals) do
    Enum.reduce(goals, fn g, acc ->
      fn %S{} = state ->
        state |> delay_goal(acc).() |> D.flat_map(g)
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
  Return a thunk that, when forced, evaluates the goal on the state.
  """
  def delay(state, goal) do
    fn ->
      goal.(state)
    end
  end

  @doc """
  Return a goal that wraps the given goal in a thunk.
  """
  def delay_goal(goal) do
    fn %S{} = state ->
      fn -> goal.(state) end
    end
  end

  @doc """
  Call a goal on an empty state and return the result as an Elixir Stream.
  """
  def call_on_empty(goal), do: goal.(S.empty()) |> D.to_stream()

  @doc """
  Non-relational if-then-else rule. If the _condition_ goal succeeds, the _conclusion_ goal is
  pursued; otherwise, the _alternative_ goal is pursued.
  """
  def switch(goal_cond, goal_conc, goal_alt) do
    fn %S{} = state ->
      do_switch(state, goal_cond.(state), goal_conc, goal_alt)
    end
  end

  defp do_switch(_state, [_h | _t] = stream, g_conc, _g_else), do: D.flat_map(stream, g_conc)
  defp do_switch(state, [], _g_conc, g_alt), do: g_alt.(state)

  defp do_switch(state, stream, g_conc, g_alt) when is_function(stream) do
    fn -> do_switch(state, stream.(), g_conc, g_alt) end
  end

  @doc """
  Non-relational _negation as failure_ that effectively negates a single goal.

  WARNING: Experimental.
  """
  def negate(goal) do
    fn %S{} = state ->
      switch(goal, failure(), success()).(state)
    end
  end

  def gt(term1, term2), do: nonrel_inequality(term1, term2, &Kernel.>/2)
  def lt(term1, term2), do: nonrel_inequality(term1, term2, &Kernel.</2)
  def gte(term1, term2), do: nonrel_inequality(term1, term2, &Kernel.>=/2)
  def lte(term1, term2), do: nonrel_inequality(term1, term2, &Kernel.<=/2)

  defp nonrel_inequality(term1, term2, op) when is_function(op) do
    fn %S{} = state ->
      term1_walked = S.walk(state, term1)
      term2_walked = S.walk(state, term2)

      if op.(term1_walked, term2_walked) do
        D.single(state)
      else
        D.empty()
      end
    end
  end
end
