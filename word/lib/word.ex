defmodule Word do
  @moduledoc """
  Documentation for `Word`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Word.hello()
      :world

  """

  # path = input/test

  def count(path) do
    File.stream!(path, :line)
      |> Flow.from_enumerable()
      |> Flow.flat_map(&String.split(&1, ~r/[^\w'-]|(?<!\w)'|'(?!\w)|_/u, trim: true))
      |> Flow.map(&String.downcase/1)
      |> Flow.partition()
      |> Flow.reduce(fn -> %{} end, fn word, acc ->
        Map.update(acc, word, 1, & &1 + 1)
      end)
      |> Enum.to_list()
  end
end
