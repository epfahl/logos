defmodule Logos.CoreNonRel do
  @moduledoc """
  Primitive non-relational rules.
  """

  alias Logos.Core, as: C
  alias Logos.State, as: S
  alias Logos.DelayedList, as: D

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

  ## Examples

    iex> import Logos.Core
    iex> import Logos.CoreNonRel
    iex> alias Logos.Variable, as: V
    iex> x = V.new(:x)
    iex> both(equal(x, 1), negate(equal(x, 2))) |> call_on_empty() |> Enum.to_list()
    [
      %Logos.State{count: 0, sub: %{%Logos.Variable{id: :x} => 1}}
    ]
  """
  def negate(goal) do
    fn %S{} = state ->
      switch(goal, C.failure(), C.success()).(state)
    end
  end

  @doc """
  Non-relational _greater than_ (>) for grounded terms.

  ## Examples

    iex> import Logos.Core
    iex> import Logos.CoreNonRel
    iex> alias Logos.Variable, as: V
    iex> x = V.new(:x)
    iex> both(equal(x, 1), gt(x, 0)) |> call_on_empty() |> Enum.to_list()
    [
      %Logos.State{count: 0, sub: %{%Logos.Variable{id: :x} => 1}}
    ]
    iex> both(equal(x, 1), gt(x, 10)) |> call_on_empty() |> Enum.to_list()
    []
  """
  def gt(term1, term2), do: nonrel_bincond(term1, term2, &Kernel.>/2)

  @doc """
  Non-relational less than_ (<) for grounded terms.
  """
  def lt(term1, term2), do: nonrel_bincond(term1, term2, &Kernel.</2)

  @doc """
  Non-relational _greater than or equal_ (>=) for grounded terms.
  """
  def gte(term1, term2), do: nonrel_bincond(term1, term2, &Kernel.>=/2)

  @doc """
  Non-relational _less than or equal_ (<=) for grounded terms.
  """
  def lte(term1, term2), do: nonrel_bincond(term1, term2, &Kernel.<=/2)

  @doc """
  Non-relational syntactic disequality.
  """
  def neq(term1, term2), do: nonrel_bincond(term1, term2, &Kernel.!=/2)

  @doc """
  Non-relational addition.
  """
  def add(term1, term2, result), do: nonrel_binarith(term1, term2, result, &Kernel.+/2)

  @doc """
  Non-relational subtraction.
  """
  def sub(term1, term2, result), do: nonrel_binarith(term1, term2, result, &Kernel.-/2)

  @doc """
  Non-relational multiplication.
  """
  def mult(term1, term2, result), do: nonrel_binarith(term1, term2, result, &Kernel.*/2)

  @doc """
  Non-relational division.
  """
  def div(term1, term2, result), do: nonrel_binarith(term1, term2, result, &Kernel.//2)

  @doc """
  Non-relational list sum.
  """
  def sum(term, result), do: nonrel_unlist(term, result, &Enum.sum/1)

  @doc """
  Non-relational list count (length).
  """
  def count(term, result), do: nonrel_unlist(term, result, &length/1)

  # NOTE: Should all of these walks be deep walks?
  # See `project` in miniK

  # Abstracted implementation of non-relational binary conditional operations.
  defp nonrel_bincond(term1, term2, op) when is_function(op) do
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

  # Abstracted implementation of non-relational binary arithmetic operations.
  defp nonrel_binarith(term1, term2, result, op) when is_function(op) do
    fn %S{} = state ->
      term1_walked = S.walk(state, term1)
      term2_walked = S.walk(state, term2)

      case {term1_walked, term2_walked} do
        {x, y} when is_number(x) and is_number(y) -> C.equal(result, op.(x, y)).(state)
        _ -> D.empty()
      end
    end
  end

  # Abstracted implementation of non-relational unary list operations.
  defp nonrel_unlist(term, result, op) when is_function(op) do
    fn %S{} = state ->
      term_walked = S.walk_deep(state, term)

      case term_walked do
        l when is_list(l) -> C.equal(result, op.(l)).(state)
        _ -> D.empty()
      end
    end
  end
end
