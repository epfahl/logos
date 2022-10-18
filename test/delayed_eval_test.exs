defmodule DelayedEvalTest do
  use ExUnit.Case, async: true
  doctest Logos.DelayedEval

  import Logos.DelayedEval

  test "delay and force" do
    d = delay(Enum.sum([1, 2, 3]))

    assert is_promise(d)
    assert force(d) == 6
  end
end
