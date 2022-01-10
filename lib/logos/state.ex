defmodule Logos.State do
  @moduledoc """
  Defines the state struct and functions for interacting with the state.

  The state holds a counter for the number of created logical variables, and a map from variables to their subitution values. All low-level interactions with a state take place through the functions in this module.
  """
  alias __MODULE__, as: S

  defstruct sub: %{}, count: 0

  @doc """
  Create a state with a counter set to 0 and an empty subitution map.
  """
  def empty(), do: %S{}

  @doc """
  Fetch the value assocaited with the given logical `var`. This returns `{:ok, value}` if `var` is present, and `:error` otherwise.
  """
  def fetch_sub(%S{sub: sub}, key), do: Map.fetch(sub, key)

  @doc """
  Extend the state substitution with the given key and value.
  """
  def put_sub(%S{sub: sub} = state, key, value), do: %{state | sub: Map.put(sub, key, value)}

  @doc """
  Increment the variable count in the state.
  """
  def inc_count(%S{count: c} = state), do: %{state | count: c + 1}

  @doc """
  Retrieve the value associated with a term by traversing the relationships between variables in the state, and stopping when the value is a list or constant.
  """
  def walk(%S{} = state, term) do
    case fetch_sub(state, term) do
      {:ok, t} -> walk(state, t)
      :error -> term
    end
  end

  @doc """
  Deeply traverse the state by walking both variables and lists that may contain variables.
  """
  def walk_deep(%S{} = state, term) do
    term_walked = walk(state, term)
    do_walk_deep(state, term_walked)
  end

  defp do_walk_deep(state, [h | t]), do: [walk_deep(state, h) | walk_deep(state, t)]
  defp do_walk_deep(_state, term), do: term
end
