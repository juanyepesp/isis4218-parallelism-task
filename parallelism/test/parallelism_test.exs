defmodule ParallelismTest do
  use ExUnit.Case
  doctest Parallelism

  test "greets the world" do
    assert Parallelism.hello() == :world
  end
end
