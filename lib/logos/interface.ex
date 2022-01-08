defmodule Logos.Interface do
  @moduledoc """
  A set of macros that define the main public interface for `Logos`.
  """

  alias Logos.Core, as: C
  alias Logos.Variable, as: V
  alias Logos.Presentation, as: P
  alias Logos.Interface, as: I

  @doc """
  Return a goal that is the disjunction over conjunction clauses, where each clause is a list of goals that represents and implicit conjunction.
  """
  defmacro fork(do: clause_block) do
    clauses = fork_clauses(clause_block)

    quote do
      unquote(clauses)
      |> Enum.map(fn
        clause when is_list(clause) -> C.all(clause)
        clause -> clause
      end)
      |> C.any()
    end
  end

  # Get the list of zero or more `any` clauses from the code block with 0 or more elements
  defp fork_clauses({:__block__, _, clauses}), do: clauses
  defp fork_clauses(clause), do: [clause]

  @doc """
  Inject logical variables into a relational expression and return the resulting goal. If `with_vars` is given a list of goals, it is treated as an implicit conjunction.
  """
  defmacro with_vars([var | t], do: any_clause_block) do
    quote do
      C.with_var(fn unquote(var) ->
        I.with_vars unquote(t) do
          unquote(any_clause_block)
        end
      end)
    end
  end

  defmacro with_vars([], do: any_clause_block) do
    quote do
      I.fork do
        unquote(any_clause_block)
      end
    end
  end

  @doc """
  Execute a query for a list of requested variables by calling the provided goal with an empty state. The results are provided as an Elixir stream. If `ask` is given a list of goals, it is treated as an implicit conjunction.
  """
  defmacro ask(vars, do: any_clause_block) when is_list(vars) do
    quote do
      out = V.new(:out)

      Logos.Interface.with_vars unquote(vars) do
        [
          C.equal(out, unquote(vars)),
          I.fork do
            unquote(any_clause_block)
          end
        ]
      end
      |> C.call_on_empty()
      |> Stream.map(&P.present(out).(&1))
    end
  end

  @doc """
  Define a named logical rule.
  """
  defmacro defrule({name, _, args}, do: any_clause_block) do
    quote do
      def unquote(name)(unquote_splicing(args)) do
        I.fork do
          unquote(any_clause_block)
        end
      end
    end
  end

  @doc """

  Notes
  * `switch` is a normal function and can't parse an implicit conjunction.
  * Generalize this to work with any kind of right-hand goal, and implicit conjunctions on the left?
  """
  defmacro choice(do: [choice_clause]) do
    [g_cond, g_then] = choice_goals(choice_clause)

    quote do
      C.all([unquote(g_cond), unquote(g_then)])
    end
  end

  defmacro choice(do: [choice_clause | t]) do
    [g_cond, g_then] = choice_goals(choice_clause)

    quote do
      C.switch(unquote(g_cond), unquote(g_then), I.choice(do: unquote(t)))
    end
  end

  defp choice_goals({:->, _, [[g_cond], g_then]}), do: [g_cond, g_then]
end
