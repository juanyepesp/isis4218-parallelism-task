defmodule Rotate do
  def run do
    case Image.open("input/image.jpeg") do
      {:ok, image} ->
        rotated_image = Image.rotate!(image, 90)

        Image.write(rotated_image, "output/image-90.jpeg")

      {:error, reason} ->
        IO.puts("Failed to open image: #{inspect(reason)}")
    end
  end

end
