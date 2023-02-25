defmodule Fledex.Color.Names do
  alias NimbleCSV.RFC4180, as: CSV
  defmacro __using__(_opts) do
    # Name ,Hex (RGB) ,Red (RGB) ,Green (RGB) ,Blue (RGB) ,Hue (HSL/HSV) ,Satur. (HSL) ,Light (HSL) ,Satur.(HSV) ,Value (HSV),Source

    root_dir = Path.dirname(__DIR__)

    colors = "#{root_dir}/color/names.csv"
      |> File.stream!()
      |> CSV.parse_stream()
      |> Stream.map(fn [name, hex, r, g, b, h, s1, l1, s2, v2, _source] ->
        %{
          name: convert_to_atom(name),
          hex: clean_and_convert(hex),
          rgb: {to_byte(r), to_byte(g), to_byte(b)},
          hsl: {to_byte(h), to_byte(s1), to_byte(l1)},
          hsv: {to_byte(h), to_byte(s2), to_byte(v2)}
        }
      end)
      |> Enum.to_list()

    quote do
      @colors unquote(Macro.escape(colors))
      def colors() do
        @colors
      end
      def names() do
        Enum.map(@colors, fn %{name: name} = _colorinfo -> name end)
      end
      def get_color_int(name) do
        colorinfo = Enum.find(@colors, fn colorinfo -> colorinfo.name == name end)
        colorinfo.hex
      end
    end
  end

  def convert_to_atom(name) do
    name
      |> String.trim()
      |> String.normalize(:nfd)
      |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
      |> String.replace(~r/__+/, "_")
      |> String.downcase(:ascii)
      |> String.to_atom()

  end
  def clean_and_convert(hex_string) do
    hex_string = String.replace(hex_string, "#", "")
    {hex_int,_} = Integer.parse(hex_string, 16)
    hex_int
  end
  def to_byte(value) do
    value = String.trim(value)
      |> String.replace("—", "0")

    case Float.parse(value) do
      {value, "%"} -> trunc((value/100) * 255)
      {value, "°"} -> trunc((value/360) * 255)
      _ -> raise "Error in converting to byte value (#{value})"
    end
  end
end
