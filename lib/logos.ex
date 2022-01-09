defmodule Logos do
  @moduledoc """
  This module allows a user to access the main public API via `use Logos`.
  """

  @default_opts %{with_occurs: false}

  defmacro __using__(_opts \\ []) do
    quote do
      import Logos.Core, only: [all: 1, any: 1, equal: 2, failure: 0, success: 0]
      import Logos.Interface, only: [ask: 2, choice: 1, fork: 1, with_vars: 2]
      import Logos.Rule
    end
  end

  defp parse_opts(opts) do
    Enum.into(opts, @default_opts)
  end
end
