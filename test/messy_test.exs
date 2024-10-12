defmodule MessyTest do
  use ExUnit.Case
  doctest Messy

  test "greets the world" do
    assert Messy.hello() == :world
  end
end
