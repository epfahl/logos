defmodule Logos.DelayedList do
  @moduledoc """
  Functions needed for interacting with a delayed list--a custom stream-like implementation that largely mirrors what is used in miniKanren and µKanren.
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
  Interleave a pair of delayed lists.

  This is similar to `mplus` in µKanren.
  """
  def interleave(dl1, dl2)
  def interleave([], dl2), do: dl2

  def interleave(dl1, dl2) when is_function(dl1, 0),
    do: fn -> interleave(dl2, dl1.()) end

  def interleave([h | t], dl2), do: [h | interleave(dl2, t)]
  def interleave([dl]), do: dl

  @doc """
  Interleave a list of delayed lists.
  """
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
  defp stream_next(dl) when is_function(dl), do: {[], dl.()}
  defp stream_next([h | t]), do: {[h], t}
end
