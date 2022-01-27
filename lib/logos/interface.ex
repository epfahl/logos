defmodule Logos.Interface do
  @moduledoc """
  A set of macros that define the main public interface for `Logos`.
  """

  alias Logos.Core, as: C
  alias Logos.Variable, as: V
  alias Logos.Presentation, as: P
  alias Logos.Interface, as: I

  @doc """
  Turn a list of goals into a conjunction (via `all`). A single goal is passed through unchanged.
  """
  def implicit_all(goals) when is_list(goals), do: C.all(goals)
  def implicit_all(goal), do: goal

  @doc """
  Return a goal that is the disjunction over conjunction clauses, where each clause is a list of
  goals that represents and implicit conjunction.
  """
  defmacro fork(do: clause_block) do
    clauses = fork_clauses(clause_block)

    quote do
      unquote(clauses)
      |> Enum.map(&I.implicit_all/1)
      |> C.any()
    end
  end

  # Get the list of zero or more `any` clauses from the code block with 0 or more elements
  defp fork_clauses({:__block__, _, clauses}), do: clauses
  defp fork_clauses(clause), do: [clause]

  @doc """
  Inject logical variables into a relational expression and return the resulting goal. If
  `with_vars` is given a list of goals, it is treated as an implicit conjunction.
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
  Execute a query for a list of requested variables by calling the provided goal with an empty
  state. The results are provided as an Elixir stream. If `ask` is given a list of goals, it is
  treated as an implicit conjunction.
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
  "Impure" relation that evaluates the first consequence whose corresponding condition goal is
  successful. Implicit conjunction is allowed for both the condition and consequence clauses.
  This is essentially eqivalent to `conda` in miniKanren.
  """
  defmacro choice(do: [clause | other_clauses]) do
    [g_cond, g_cnsq] = choice_goals(clause)

    do_choice(g_cond, g_cnsq, other_clauses)
  end

  defp do_choice(g_cond, g_cnsq, []) do
    quote do
      [unquote(g_cond), unquote(g_cnsq)]
      |> Enum.map(&I.implicit_all/1)
      |> C.all()
    end
  end

  defp do_choice(g_cond, g_cnsq, [_h | _t] = clauses) do
    quote do
      C.switch(
        I.implicit_all(unquote(g_cond)),
        I.implicit_all(unquote(g_cnsq)),
        I.choice(do: unquote(clauses))
      )
    end
  end

  # Extract the condition and consequence goals from a quoted line in the choice macro
  defp choice_goals({:->, _, [[g_cond], g_cnsq]}), do: [g_cond, g_cnsq]
end
