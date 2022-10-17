defmodule Logos.DelayedList do
  @moduledoc """
  Functions needed for interacting with a delayed list--a custom stream-like implementation that
  largely mirrors what is used in miniKanren and µKanren.
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
  Binary version of interleave. Using the miniK name for now.
  """
  def mplus([], dl2), do: dl2
  def mplus([h1 | t1], dl2), do: [h1 | mplus(dl2, t1) |> delay()]
  def mplus(dl1, dl2) when is_promise(dl1), do: mplus(dl2, force(dl1)) |> delay()

  @doc """
  Binary version of flat_map. Using the miniK name for now.
  """
  def bind([], _mapper), do: []
  def bind([h | t], mapper), do: mplus(mapper.(h) |> delay(), bind(t, mapper) |> delay())
  def bind(dl, mapper) when is_promise(dl), do: dl |> force() |> bind(mapper) |> delay()

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
