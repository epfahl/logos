defmodule Logos do
  @moduledoc """
  This module allows a user to access the main public API via `use Logos`.
  """

  defmacro __using__(_opts \\ []) do
    quote do
      import Logos.Core, only: [all: 1, any: 1, equal: 2, failure: 0, success: 0]

      import Logos.CoreNonRel,
        only: [
          gt: 2,
          gte: 2,
          lt: 2,
          lte: 2,
          negate: 1,
          neq: 2,
          add: 2,
          sub: 2,
          mult: 2,
          div: 2,
          sum: 1,
          count: 1
        ]

      import Logos.Interface, only: [ask: 2, choice: 1, defrule: 2, fork: 1, neg: 1, with_vars: 2]
      import Logos.Rule
    end
  end
end
