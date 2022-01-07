defmodule Logos.Interface do
  @moduledoc """
  A set of macros that define the main public interface for `Logos`.
  """

  alias Logos.Core, as: C
  alias Logos.Variable, as: V
  alias Logos.Presentation, as: P

  @doc """
  Return a goal that is the disjunction over conjunction clauses, where each clause is a list of goals that represents and implicit conjunction.
  """
  defmacro fork(do: clause_block) do
    any_clauses = to_any_clauses(clause_block)

    quote do
      unquote(any_clauses)
      |> Enum.map(fn
        clause when is_list(clause) -> C.all(clause)
        clause -> clause
      end)
      |> C.any()
    end
  end

  # Get the list of zero or more `any` clauses from the code block with 0 or more elements
  defp to_any_clauses({:__block__, _, clauses}), do: clauses
  defp to_any_clauses(clause), do: [clause]

  @doc """
  Inject logical variables into a relational expression and return the resulting goal. If `with_vars` is given a list of goals, it is treated as an implicit conjunction.
  """
  defmacro with_vars([h | t], do: clause_block) do
    quote do
      C.with_var(fn unquote(h) ->
        Logos.Interface.with_vars unquote(t) do
          unquote(clause_block)
        end
      end)
    end
  end

  defmacro with_vars([], do: clause_block) do
    quote do
      Logos.Interface.fork do
        unquote(clause_block)
      end
    end
  end

  @doc """
  Execute a query for a list of requested variables by calling the provided goal with an empty state. The results are provided as an Elixir stream. If `ask` is given a list of goals, it is treated as an implicit conjunction.
  """
  defmacro ask(vars, do: clause_block) when is_list(vars) do
    quote do
      out = V.new(:out)

      Logos.Interface.with_vars unquote(vars) do
        [
          C.equal(out, unquote(vars)),
          Logos.Interface.fork do
            unquote(clause_block)
          end
        ]
      end
      |> C.call_on_empty()
      |> Stream.map(&P.present(out).(&1))
    end
  end

  defmacro defrule({name, _, args}, do: clause_block) do
    quote do
      def unquote(name)(unquote_splicing(args)) do
        Logos.Interface.fork do
          unquote(clause_block)
        end
      end
    end
  end
end
