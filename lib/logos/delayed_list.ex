defmodule Logos.DelayedList do
  @moduledoc """
  Functions needed for interacting with a delayed list--a custom stream-like implementation that
  largely mirrors what is used in miniKanren and µKanren.
  """

  @doc """
  Return an empty delayed list as an ordinary empty list.
  """
  def empty(), do: []

  @doc """
  Return a delayed list containing single item.
  """
  def single(x), do: [x]

  @doc """
  Binary version of interleave. Using the miniK name for now.
  """
  def mplus([], dl2), do: dl2
  def mplus([h1 | t1], dl2), do: [h1 | fn -> mplus(dl2, t1) end]
  def mplus(dl1, dl2) when is_function(dl1, 0), do: fn -> mplus(dl2, dl1.()) end

  @doc """
  Binary versio of flat_map. Using the miniK name for now.
  """
  def bind([], _mapper), do: []

  # pause/delay should go here
  def bind([h | t], mapper), do: mplus(fn -> mapper.(h) end, fn -> bind(t, mapper) end)
  def bind(dl, mapper) when is_function(dl, 0), do: fn -> bind(dl.(), mapper) end

  @doc """
  Interleave a pair of delayed lists.

  This is similar to `mplus` in µKanren.

  ## Examples

    iex> import Logos.DelayedList
    iex> interleave([1, 2, 3], ["a", "b", "c"]) |> take(6)
    [1, "a", 2, "b", 3, "c"]
    iex> interleave([1, 2], ["a", "b", "c"]) |> take(5)
    [1, "a", 2, "b", "c"]
  """
  def interleave(dl1, dl2)
  def interleave([], dl2), do: dl2

  def interleave(dl1, dl2) when is_function(dl1, 0),
    do: fn -> interleave(dl2, dl1.()) end

  # Yields an improper list; mimics mplus implementation in Rosenblatt et al. (2019)
  def interleave([h | t], dl2), do: [h | fn -> interleave(dl2, t) end]

  @doc """
  Interleave a list of delayed lists.

  ## Examples

    iex> import Logos.DelayedList
    iex> interleave([[1, 2], ["a", "b", "c"], [:one, :two]]) |> take(7)
    [1, "a", 2, :one, "b", :two, "c"]
  """
  def interleave([dl]), do: dl
  def interleave([h | t]), do: interleave(h, interleave(t))

  @doc """
  Given a mapping function that returns a delayed list, return a flattened delayed list.

  This is similar to `bind` in µKanren.
  """
  def flat_map(dl, mapper)
  def flat_map([h | t], mapper), do: interleave(mapper.(h), flat_map(t, mapper))
  def flat_map([], _mapper), do: []

  def flat_map(dl, mapper) when is_function(dl, 0),
    do: fn -> flat_map(dl.(), mapper) end

  @doc """
  Advance the stream until it is a list, a "mature" stream in the language of miniKanren.
  """
  def advance(dl) when is_list(dl), do: dl
  def advance(dl) when is_function(dl, 0), do: advance(dl.())

  @doc """
  Return a list of the first `n` concrete elements.
  """
  def take(_dl, 0), do: []

  def take(dl, n) when is_integer(n) and n > 0 do
    case advance(dl) do
      [h | t] -> [h | take(t, n - 1)]
      _ -> []
    end
  end

  @doc """
  Convert a delayed list to an Elixir `Stream`.
  """
  def to_stream(dl) do
    Stream.resource(
      fn -> dl end,
      &stream_next/1,
      fn items -> items end
    )
  end

  defp stream_next([]), do: {:halt, []}
  defp stream_next(dl) when is_function(dl, 0), do: {[], dl.()}
  defp stream_next([h | t]), do: {[h], t}
end
