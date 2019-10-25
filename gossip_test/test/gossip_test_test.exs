defmodule GossipTestTest do
  use ExUnit.Case
  doctest GossipTest

  test "greets the world" do
    assert GossipTest.hello() == :world
  end
end
