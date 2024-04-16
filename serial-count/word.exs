defmodule Word do
  def seq do
     Enum.map(1..5, &"words/list#{&1}")
       |> load_from_files()
       |> Enum.flat_map(&String.split/1)
       |> Enum.reduce(%{}, fn word, map -> count(word, map) end)
  end

  defp load_from_files(file_names) do
     file_names
       |> Task.async_stream(fn name -> load_file(name) end)
       |> Enum.flat_map(fn {:ok, lines} -> lines end)
  end

  defp load_file(name) do
     File.stream!(name, [], :line)
       |> Enum.map(&String.trim/1)
  end

  defp count(word, map) do
     Map.update(map, word, 1, &(&1 + 1))
  end
 end
