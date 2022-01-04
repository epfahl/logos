defmodule Logos.Interface do
  @moduledoc """

  """

  alias Logos.Core, as: C
  alias Logos.Variable, as: V
  alias Logos.Presentation, as: P

  @doc """
  Inject logical variables into a rule and return the resulting goal. If `with_vars` is given a list of goals, it is treated as an implicit conjunction.
  """
  defmacro with_vars(vars, do: goal) when is_list(vars) do
    goals = List.wrap(goal)
    do_with_vars(vars, goals)
  end

  defp do_with_vars([], goals) do
    quote do: C.all(unquote(goals))
  end

  defp do_with_vars([h | t], goals) do
    quote do
      C.with_var(fn unquote(h) ->
        Logos.Interface.with_vars unquote(t) do
          unquote(goals)
        end
      end)
    end
  end

  @doc """
  Execute a query for a list of requested variables by calling the provided goal with an empty state. The results are provided as an Elixir stream. If `ask` is given a list of goals, it is treated as an implicit conjunction.
  """
  defmacro ask(vars, do: goal) when is_list(vars) do
    goals = List.wrap(goal)

    quote do
      out = V.new(:out)

      Logos.Interface.with_vars unquote(vars) do
        [C.equal(out, unquote(vars)) | unquote(goals)]
      end
      |> C.call_on_empty()
      |> Stream.map(&P.present(out).(&1))
    end
  end

  @doc """
  Return a goal that is the disjunction over conjunction clauses, where each clause is a list of goals that represents and implicit conjunction.
  """
  defmacro fork(do: {:__block__, _, clauses}) do
    quote do
      unquote(clauses)
      |> Enum.map(&C.all/1)
      |> C.any()
    end
  end

  defmacro fork(do: clause) when is_list(clause) do
    clauses = {:__block__, [], [clause]}

    quote do
      Logos.Interface.fork do
        unquote(clauses)
      end
    end
  end
end
