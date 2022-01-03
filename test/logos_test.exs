defmodule LogosTest do
  use ExUnit.Case
  doctest Logos

  test "greets the world" do
    assert Logos.hello() == :world
  end
end
