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

  defp remote_count(list) do
    chunk_size = Float.ceil(length(list) / System.schedulers_online()) |> trunc()
    chunks = Enum.chunk_every(list, chunk_size)

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

  defp rotate_helper(chunk, width, height, angle, pixels) do
    # Calculate the sine and cosine of the angle
    sin_angle = Math.sin(angle)
    cos_angle = Math.cos(angle)

    # Center of rotation
    x0 = 0.5 * (width - 1)
    y0 = 0.5 * (height - 1)

    # Rotate the image. This can be done in parallel
    rotated_pixels =
      Enum.map(chunk, fn y ->
        Enum.map(0..(width-1), fn x ->
          a = x - x0
          b = y - y0
          xf = floor( + a * cos_angle - b * sin_angle + x0)
          yf = floor( + a * sin_angle + b * cos_angle + y0)

          pixel =
            if xf >= 0 && xf < width && yf >= 0 && yf < height do
              Enum.at(Enum.at(pixels, yf), xf)
            else
              {0, 0, 0}
            end
          {Kernel.elem(pixel, 0), Kernel.elem(pixel, 1), Kernel.elem(pixel, 2)}
        end)
      end)

    rotated_pixels
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

  defp rotate(image, angle, pids) do
    pid_amount = length(pids)

    # Define the rotation angle in radians
    deg = String.replace(angle, "\n", "") |> String.to_integer()
    angle = Math.deg2rad(deg)

    width = image.width
    height = image.height
    pixels = image.pixels

    chunk_size = Float.ceil(height / pid_amount) |> trunc()
    chunks = Enum.chunk_every(0..(height-1), chunk_size)
    zipped = Enum.zip(pids, chunks)

    Enum.each(zipped, fn {pid, chunk} ->
      send(pid, {self(), :rotate, {chunk, width, height, angle, pixels}})
    end)

    # receive rotated chunks from workers
    rotated_chunks = Enum.reduce(1..pid_amount, [], fn _, acc ->
      receive do
        {_pid, :reply, result} ->
          [result | acc]
      end
    end)

    # Reunite all of the rows
    rotated_pixels = Enum.reduce(rotated_chunks, [], fn chunk, acc ->
      acc ++ chunk
    end)


    rotated_image = %Imagineer.Image.PNG{
      alias: nil,
      width: image.width,
      height: image.height,
      bit_depth: image.bit_depth,
      color_type: image.color_type,
      color_format: image.color_format,
      uri: nil,
      format: :png,
      attributes: %{},
      data_content: Imagineer.Image.PNG.Pixels.NoInterlace.encode_pixel_rows(rotated_pixels, image),
      raw: nil,
      comment: nil,
      mask: nil,
      compression: image.compression,
      decompressed_data: nil,
      unfiltered_rows: [],
      scanlines: [],
      filter_method: image.filter_method,
      interlace_method: 0,
      gamma: nil,
      palette: [],
      pixels: rotated_pixels,
      mime_type: "image/png",
      background: nil,
      transparency: nil
    }

    rotated_image
  end # Here it should reunite all of the rowsx

  defp morph(image1, image2) do
    :ok
  end

  defp save_image(image, path) do
    :ok = Imagineer.write(image, path)
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

  defp load_image() do
    file_path =
      IO.gets("\nEnter file path (with extension) to load image from: ") |> String.trim()

    IO.puts("\nLoading image from file: #{file_path} ...")

    case Imagineer.load("data/image.png") do
      {:ok, image} ->
        IO.puts("Image loaded successfully")
        image

      {:error, reason} ->
        IO.inspect("Error loading image: #{reason}")
        nil
    end
  end

  defp execution_loop do
    receive do
      {pid, msg} ->
        # IO.inspect("Received message: #{msg}")
        send(pid, {self(), :reply, "Message #{msg} received on pid #{inspect(self())}"})

      {pid, :count, list} ->
        # IO.inspect("")
        send(pid, {self(), :reply, remote_count(list)})

      {pid, :rotate, {chunk, width, height, angle, pixels}} ->
        send(pid, {self(), :reply, rotate_helper(chunk, width, height, angle, pixels)})

      {:kill} ->
        IO.puts("Killing worker with pid: #{inspect(self())}")
        exit(:normal)
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
    IO.puts("1. Show connected nodes")
    IO.puts("2. Start remote workers")
    IO.puts("3. Stop remote workers")
    IO.puts("4. Load text")
    IO.puts("5. Load image 1")
    IO.puts("6. Load image 2")
    IO.puts("7. Count words in text")
    IO.puts("8. Rotate image")
    IO.puts("9. Morph images")
    IO.puts("10. Exit")

    action = IO.gets("\nEnter action number: ") |> String.trim()

    case action do
      "0" ->
        connect_node()
        action_loop(text, image1, image2, pids)

      "1" ->
        show_connected_nodes()
        action_loop(text, image1, image2, pids)

      "2" ->
        action_loop(text, image1, image2, start_node_workers())

      "3" ->
        Enum.each(pids, fn pid -> send(pid, :kill) end)
        action_loop(text, image1, image2, nil)

      "4" ->
        action_loop(load_content(), image1, image2, pids)

      "5" ->
        action_loop(text, load_image(), image2, pids)

      "6" ->
        action_loop(text, image1, load_image(), pids)

      "7" ->
        start = :os.system_time(:millisecond)
        word_count = count(text, pids)
        time = :os.system_time(:millisecond) - start
        IO.inspect(word_count)
        IO.puts("\nTime taken ms: #{time}ms")
        IO.puts("Time taken s: #{time / 1000}s")
        action_loop(text, image1, image2, pids)

      "8" ->
        angle = IO.gets("Enter angle to rotate image by:")
        start = :os.system_time(:millisecond)
        rotated_image = rotate(image1, angle, pids)
        time = :os.system_time(:millisecond) - start
        IO.puts("\nTime taken ms: #{time}ms")
        IO.puts("Time taken s: #{time / 1000}s")

        save_image(rotated_image, "./data/image-rotated.png")
        action_loop(text, image1, image2, pids)

      "9" ->
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
