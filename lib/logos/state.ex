defmodule Logos.State do
  @moduledoc """
  The state holds a counter for the number of created logical variables, and a map from varialbes to their subitution values. All low-level interactions with a state take place through the functions in this module.
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
end
