defmodule Logos.Core do
  @moduledoc """
  Primitive relations and helpers.

  This is essentially the microKanren functional core, supplemented with list forms `any`
  and `all` and helper functions.
  """

  alias Logos.Unification, as: U
  alias Logos.Variable, as: V
  alias Logos.State, as: S
  alias Logos.DelayedList, as: D

  @doc """
  Return a goal that leaves the state unaltersed and lifts it into a delayed list.
  """
  def success(), do: fn %S{} = state -> D.single(state) end

  @doc """
  Return a goal that yields an empty delayed list.
  """
  def failure(), do: fn %S{} = _state -> D.empty() end

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
      D.mplus(goal1.(state), goal2.(state))
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
      D.bind(goal1.(state), goal2)
    end
  end

  @doc """
  Return a goal that represents disjunction over zero or more goals.
  """
  def any([]), do: failure()
  def any([goal]), do: goal
  def any([goal | t]), do: either(goal, any(t))

  @doc """
  Return a goal that represents conjunction over zero or more goals.
  """
  def all([]), do: success()
  def all([goal]), do: goal
  def all([goal | t]), do: both(goal, all(t))

  @doc """
  Return a goal that injects a new variable into a function-wrapped goal.
  """
  def with_var(var_to_goal) when is_function(var_to_goal, 1) do
    fn %S{} = state ->
      state |> S.inc_count() |> var_to_goal.(V.new(state.count)).()
    end
  end

  @doc """
  Call a goal on an empty state and return the result as an Elixir Stream.
  """
  def call_on_empty(goal), do: S.empty() |> goal.() |> D.to_stream()
end
