# Esteban Gonzalez Ruales - 202021225 - e.gonzalez5
# Juan Diego Yepes - 202022391 - j.yepes
# Felipe Nuñez - 202021673 - f.nunez

# Task 1

defmodule Task1 do
  @cores System.schedulers_online()

  @doc """
  Count the number of words in the sentence.
  Words are compared case-insensitively.
  """
  @spec count(String.t()) :: map
  def count(nil), do: %{}

  def count(str) do
    words = String.split(str, ~r/[^a-zA-Z0-9']+/)
    chunk_size = div(length(words), @cores)
    chunks = Enum.chunk_every(words, chunk_size)

    Task.async_stream(chunks, fn chunk ->
      count_helper(chunk)
    end)
    |> Stream.map(fn {:ok, result} -> result end)
    |> Enum.reduce(fn map1, map2 ->
      Map.merge(map1, map2, fn _, val1, val2 ->
        val1 + val2
      end)
    end)
  end

  def count_helper(list) do
    list
    |> Stream.map(&String.downcase/1)
    |> Stream.reject(&(&1 == ""))
    |> Stream.reject(&String.starts_with?(&1, "'"))
    |> Stream.reject(&String.ends_with?(&1, "'"))
    |> Enum.group_by(fn x -> x end)
    |> Stream.map(fn {k, v} -> {k, Enum.count(v)} end)
    |> Map.new(fn {k, v} -> {k, v} end)
  end

  def measure(fun) do
    warm_up_times =
      Enum.map(1..10, fn _ ->
        time = do_measure(fun)
        IO.puts("Warm-up time: #{time}")
        time
      end)

    warm_up_avg = Enum.sum(warm_up_times) / length(warm_up_times)
    IO.puts("Warmp-up average: #{warm_up_avg}")

    measurement_times =
      Enum.map(1..10, fn _ ->
        time = do_measure(fun)
        IO.puts("Measurement time: #{time}")
        time
      end)

    measurement_avg = Enum.sum(measurement_times) / length(measurement_times)
    IO.puts("Measurement average: #{measurement_avg}")
  end

  def do_measure(fun) do
    fun
    |> :timer.tc()
    |> elem(0)
    |> Kernel./(1_000_000)
  end

  def main do
    {:ok, contents} = File.read("./data/big.txt")
    measure(fn -> count(contents) end)
  end
end
