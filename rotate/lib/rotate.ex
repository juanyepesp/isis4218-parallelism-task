defmodule Rotate do
  defp rotate(image, degree) do
    Image.rotate!(image, degree)
  end

  defp crop_and_rotate(path, num_images, degree) do
    case Image.open(path) do
      {:ok, image} ->
        height = Image.height(image)
        width = Image.width(image)
        crop_height = div(height, num_images + 1)

        cropping_dimensions = for i <- 1..num_images do
          %{
            :left => 0,
            :top => i * crop_height,
            :width => width,
            :height => crop_height
          }
        end

        cropping_dimensions
        |> Enum.map(fn cropping ->
          {:ok, cropped_image} = Image.crop(image, cropping.left, cropping.top, cropping.width, cropping.height)
          rotated = rotate(cropped_image, degree)
          rotated
        end)
        |> Enum.reverse()

      {:error, reason} ->
        IO.puts("Failed to open image: #{inspect(reason)}")
        []
    end
  end

  def start do

    num_images = 5
    degree = 90

    image_objects = crop_and_rotate("input/image.jpeg", num_images, degree)

    case degree do
      90 ->
        rotated = join_horizontal(image_objects)
        Image.write(rotated, "output/image-rotated-90.jpeg")
      180 ->
        rotated = join_vertical(image_objects)
        Image.write(rotated, "output/image-rotated-180.jpeg")
      270 ->
        rotated = join_horizontal(Enum.reverse(image_objects))
        Image.write(rotated, "output/image-rotated-270.jpeg")
      _ ->
        IO.puts("Invalid degree: #{degree}")
    end
  end

  defp join_horizontal(image_objects) do
    {:ok, image} =Image.join(image_objects, [
      across: length(image_objects),
    ])
    image
  end

  defp join_vertical(image_objects) do
    {:ok, image} = Image.join(image_objects)
    image
  end

end
