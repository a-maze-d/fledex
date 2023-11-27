defmodule Fledex.Color.LoadUtils do
  def names_file, do: "#{Path.dirname(__DIR__)}/color/names.csv"
  def load_color_file(names_file) do
    # Name, Hex (RGB), Red (RGB), Green (RGB), Blue (RGB), Hue (HSL/HSV), Satur. (HSL),
    #   Light (HSL), Satur.(HSV), Value (HSV), Source
    names_file
    |> File.stream!()
    |> Stream.drop(1)
    |> Stream.with_index()
    |> Stream.map(fn {line, index} -> parse_line(index, line) end)
    |> Stream.map(fn [index, name, hex, r, g, b, h, s1, l1, s2, v2, source] ->
        %{
            index: index,
            name: convert_to_atom(name),
            descriptive_name: String.trim(name),
            hex: clean_and_convert(hex),
            rgb: {to_byte(r), to_byte(g), to_byte(b)},
            hsl: {to_byte(h), to_byte(s1), to_byte(l1)},
            hsv: {to_byte(h), to_byte(s2), to_byte(v2)},
            source: String.trim(source)
        }
        end)
    |> Enum.to_list()
  end
  def parse_line(index, line) do
    [index] ++ String.split(line, ",", parts: 11)
  end

  defp convert_to_atom(name) do
    name
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-zA-Z0-9]/, " ")
    |> String.trim()
    |> String.replace(~r/\s+/, "_")
    |> String.downcase(:ascii)
    |> String.to_atom()
  end

  defp clean_and_convert(hex_string) do
    hex_string = String.replace(hex_string, "#", "")
    {hex_int, _} = Integer.parse(hex_string, 16)
    hex_int
  end
  defp to_byte(value) do
    value = String.trim(value)
    |> String.replace("—", "0")

    case Float.parse(value) do
      {value, "%"} -> trunc((value / 100) * 255)
      {value, "°"} -> trunc((value / 360) * 255)
    end
  end
end
