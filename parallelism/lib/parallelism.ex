defmodule Parallelism do
  defp show_connected_nodes do
    IO.puts("\nNumber of nodes connected: #{Node.list() |> length}")
    IO.puts("Connected nodes:")
    IO.inspect(Node.list())
  end

  defp connect_node do
    node_name =
      IO.gets("\nEnter node name to connect to without double quotes or colon: ") |> String.trim()

    node_atom = :"#{node_name}"

    IO.puts("\nConnecting to node with atom: :#{node_atom} ...")

    case Node.connect(node_atom) do
      true -> IO.puts("Connected successfully")
      _ -> IO.puts("Error connecting to node")
    end

    show_connected_nodes()
  end

  defp count(text, pids) do
    words = String.split(text, ~r/[^a-zA-Z0-9']+/)
    pid_amount = length(pids)
    chunk_size = Float.ceil(length(words) / pid_amount) |> trunc()
    chunks = Enum.chunk_every(words, chunk_size)
    zipped = Enum.zip(pids, chunks)

    Enum.each(zipped, fn {pid, chunk} ->
      send(pid, {self(), :count, chunk})
    end)

    Enum.reduce(1..pid_amount, %{}, fn _, acc ->
      receive do
        {_pid, :reply, result} ->
          Map.merge(acc, result, fn _, val1, val2 ->
            val1 + val2
          end)
      end
    end)
  end

  defp remote_count(words) do
    chunk_size = Float.ceil(length(words) / System.schedulers_online()) |> trunc()
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

  defp count_helper(list) do
    list
    |> Stream.map(&String.downcase/1)
    |> Stream.reject(&(&1 == ""))
    |> Stream.reject(&String.starts_with?(&1, "'"))
    |> Stream.reject(&String.ends_with?(&1, "'"))
    |> Enum.group_by(fn x -> x end)
    |> Stream.map(fn {k, v} -> {k, Enum.count(v)} end)
    |> Map.new(fn {k, v} -> {k, v} end)
  end

  defp rotate(image, angle) do
  end

  defp morph(image1, image2) do
  end

  defp save_image(image, path) do
    case File.write(path, image) do
      :ok -> IO.puts("Image saved successfully")
      {:error, reason} -> IO.inspect("Error saving image: #{reason}")
    end
  end

  defp load_content() do
    file_path =
      IO.gets("\nEnter file path (with extension) to load content from: ") |> String.trim()

    IO.puts("\nLoading text from file: #{file_path} ...")

    case File.read(file_path) do
      {:ok, content} ->
        IO.puts("Text loaded successfully")
        content

      {:error, reason} ->
        IO.inspect("Error loading text: #{reason}")
        nil
    end
  end

  defp execution_loop do
    receive do
      {pid, msg} ->
        # IO.inspect("Received message: #{msg}")
        send(pid, {self(), :reply, "Message #{msg} received on pid #{inspect(self())}"})

      {pid, :count, text} ->
        # IO.inspect("")
        send(pid, {self(), :reply, remote_count(text)})
    end

    execution_loop()
  end

  defp start_node_workers do
    node_pids =
      for node <- Node.list() do
        Node.spawn(node, fn -> execution_loop() end)
      end

    IO.puts("\nStarted remote workers on remote nodes with pids:")
    IO.inspect(node_pids)
    show_connected_nodes()
    node_pids
  end

  defp action_loop(text, image1, image2, pids) do
    IO.puts("\nChoose an action to perform:")
    IO.puts("0. Connect new node")
    IO.puts("1. Start remote workers")
    IO.puts("2. Show connected nodes")
    IO.puts("3. Load text")
    IO.puts("4. Load image 1")
    IO.puts("5. Load image 2")
    IO.puts("6. Count words in text")
    IO.puts("7. Rotate image")
    IO.puts("8. Morph images")
    IO.puts("9. Exit")

    action = IO.gets("\nEnter action number: ") |> String.trim()

    case action do
      "0" ->
        connect_node()
        action_loop(text, image1, image2, pids)

      "1" ->
        action_loop(text, image1, image2, start_node_workers())

      "2" ->
        show_connected_nodes()
        action_loop(text, image1, image2, pids)

      "3" ->
        action_loop(load_content(), image1, image2, pids)

      "4" ->
        action_loop(text, load_content(), image2, pids)

      "5" ->
        action_loop(text, image1, load_content(), pids)

      "6" ->
        start = :os.system_time(:millisecond)
        word_count = count(text, pids)
        time = :os.system_time(:millisecond) - start
        IO.inspect(word_count)
        IO.puts("\nTime taken ms: #{time}ms")
        IO.puts("Time taken s: #{time / 1000}s")
        action_loop(text, image1, image2, pids)

      "7" ->
        angle = IO.gets("Enter angle to rotate image by:")
        rotated_image = rotate(image1, angle)

        save_image(rotated_image, "./data/rotated_image.png")
        action_loop(text, image1, image2, pids)

      "8" ->
        transformation_images = morph(image1, image2)
        transformation_zip = Enum.zip(transformation_images, 1..length(transformation_images))

        Enum.each(transformation_zip, fn {image, num} ->
          save_image(image, "./data/transformation_#{num}.png")
        end)

        action_loop(text, image1, image2, pids)

      _ ->
        IO.inspect("Exiting...")
    end
  end

  def main do
    action_loop(nil, nil, nil, nil)
  end
end
