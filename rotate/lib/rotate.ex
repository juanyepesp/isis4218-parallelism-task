defmodule Rotate do

  # defp rotate(image, degree) do
  #   Image.rotate!(image, degree)
  # end

  # defp crop_and_rotate(path, num_images, degree) do
  #   case Image.open(path) do
  #     {:ok, image} ->
  #       height = Image.height(image)
  #       width = Image.width(image)
  #       crop_height = div(height, num_images + 1)

  #       cropping_dimensions = for i <- 1..num_images do
  #         %{
  #           :left => 0,
  #           :top => i * crop_height,
  #           :width => width,
  #           :height => crop_height
  #         }
  #       end

  #       cropping_dimensions
  #       |> Enum.map(fn cropping ->
  #         {:ok, cropped_image} = Image.crop(image, cropping.left, cropping.top, cropping.width, cropping.height)
  #         rotated = rotate(cropped_image, degree)
  #         rotated
  #       end)
  #       |> Enum.reverse()

  #     {:error, reason} ->
  #       IO.puts("Failed to open image: #{inspect(reason)}")
  #       []
  #   end
  # end

  # def start do

  #   num_images = 5
  #   degree = 90

  #   image_objects = crop_and_rotate("input/image.jpeg", num_images, degree)

  #   case degree do
  #     90 ->
  #       rotated = join_horizontal(image_objects)
  #       Image.write(rotated, "output/image-rotated-90.jpeg")
  #     180 ->
  #       rotated = join_vertical(image_objects)
  #       Image.write(rotated, "output/image-rotated-180.jpeg")
  #     270 ->
  #       rotated = join_horizontal(Enum.reverse(image_objects))
  #       Image.write(rotated, "output/image-rotated-270.jpeg")
  #     _ ->
  #       IO.puts("Invalid degree: #{degree}")
  #   end
  # end

  # defp join_horizontal(image_objects) do
  #   {:ok, image} =Image.join(image_objects, [
  #     across: length(image_objects),
  #   ])
  #   image
  # end

  # defp join_vertical(image_objects) do
  #   {:ok, image} = Image.join(image_objects)
  #   image
  # end

  def crop_and_rotate_by_pixels() do
    # Load the image
    {_, image} = Imagineer.load("input/image.png")

    # Define the rotation angle in radians
    deg = 45
    angle = Math.deg2rad(deg)

    width = image.width
    height = image.height
    pixels = image.pixels

    # Calculate the sine and cosine of the angle
    sin_angle = Math.sin(angle)
    cos_angle = Math.cos(angle)

    # Center of rotation
    x0 = 0.5 * (width - 1)
    y0 = 0.5 * (height - 1)

    # Create a new image with the same dimensions, filled with black pixels
    # rotated_image = Enum.map(0..(height - 1), fn _ -> Enum.map(0..(width - 1), fn _ -> {0, 0, 0} end) end)

    # Rotate the image
    rotated_pixels =
      Enum.map(0..(height-1), fn y ->
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

      IO.inspect(rotated_image)

      :ok = Imagineer.write(rotated_image, "output/image-rotated-#{deg}.jpeg")

  end


end
