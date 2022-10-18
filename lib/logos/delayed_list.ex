defmodule Logos.DelayedList do
  @moduledoc """
  Functions needed for interacting with a delayed list--a custom stream-like implementation that
  largely mirrors what is used in miniKanren and microKanren.

  ## Notes
  - Include type signatures to augment documentation.
  - This stream implementation may be updated to something that can be explicitly
    paused and continued.
      - Maybe even the Enumerable stream implementation...?
  """
  import Logos.DelayedEval

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
  """
  def interleave([h1 | t1], dl2), do: [h1 | interleave(dl2, t1) |> delay()]
  def interleave(dl1, dl2) when is_promise(dl1), do: interleave(dl2, force(dl1)) |> delay()
  def interleave([], dl2), do: dl2

  @doc """
  Apply the `mapper`, a function that returns a delayed list, to each element of a
  delayed list and return a flat delayed list.
  """
  def flat_map([h | t], mapper) do
    interleave(
      mapper.(h) |> delay(),
      flat_map(t, mapper) |> delay()
    )
  end

  def flat_map(dl, mapper) when is_promise(dl), do: flat_map(force(dl), mapper) |> delay()
  def flat_map([], _mapper), do: []

  # @doc """
  # Advance the stream until it is a list, a "mature" stream in the language of miniKanren.
  # """
  # def advance(dl) when is_list(dl), do: dl
  # def advance(dl) when is_promise(dl), do: dl |> force() |> advance()

  # @doc """
  # Return a list of the first `n` concrete elements.
  # """
  # def take(_dl, 0), do: []

  # def take(dl, n) when is_integer(n) and n > 0 do
  #   case advance(dl) do
  #     [h | t] -> [h | take(t, n - 1)]
  #     _ -> []
  #   end
  # end

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
  defp stream_next(dl) when is_promise(dl), do: {[], force(dl)}

  defp stream_next([h | t]), do: {[h], t}
end
