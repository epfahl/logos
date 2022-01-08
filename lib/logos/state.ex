defmodule Logos.State do
  @moduledoc """
  Defines the struct for holding variable bindings, along with functions for interacting with the state.

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
  def fetch(%S{sub: sub}, key), do: Map.fetch(sub, key)

  @doc """
  Extend the state with the given key and value. This returns `{:ok, state}` if the extension is successful, and `:error` otherwise.
  """
  def extend_sub(
        %S{sub: sub} = state,
        key,
        value,
        check_fn \\ fn _state, _key, _value -> true end
      )
      when is_function(check_fn, 3) do
    if check_fn.(state, key, value) do
      {:ok, %{state | sub: Map.put(sub, key, value)}}
    else
      :error
    end
  end

  @doc """
  Increment the variable count in the state.
  """
  def inc_count(%S{count: c} = state), do: %{state | count: c + 1}

  @doc """
  Retrieve the value associated with a term by traversing the relationships between variables in the state, and stopping when the value is a list or constant.
  """
  def walk(%S{} = state, term) do
    case fetch(state, term) do
      {:ok, t} -> walk(state, t)
      :error -> term
    end
  end

  @doc """
  Deeply traverse the state by walking both variables and lists that may contain variables.

  Notes
  * May move to a more general place, since this has use beyond presentation, I think.
  """
  def walk_deep(%S{} = state, term) do
    wterm = walk(state, term)
    do_walk_deep(state, wterm)
  end

  defp do_walk_deep(state, [h | t]), do: [walk_deep(state, h) | walk_deep(state, t)]
  defp do_walk_deep(_state, term), do: term
end
