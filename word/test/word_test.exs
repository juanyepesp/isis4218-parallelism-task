defmodule WordTest do
  use ExUnit.Case
  doctest Word

  test "greets the world" do
    assert Word.hello() == :world
  end
end
