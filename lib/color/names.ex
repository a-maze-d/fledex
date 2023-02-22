defmodule Fledex.Color.Names do
  @moduledoc """
  This module provides a mapping from color names to color integers
  """
  @doc """
    Load this json list and convert it to a compiled structure with functions to access it

    The JSON file is from here:
    * https://www.ditig.com/256-colors-cheat-sheet
    * https://www.ditig.com/downloads/256-colors.json
  """
  defmacro __using__(_opts) do
    root_dir = Path.dirname(__DIR__)
    file = "#{root_dir}/color/256-colors.json"
    json = File.read!(file)
    {:ok, colors} = Jason.decode(json, keys: :atoms)
    names_and_rgb = Enum.map(colors, fn %{hexString: hex_string, name: name} ->
      hex_string = String.replace(hex_string, "#", "")
      {hex_int,_} = Integer.parse(hex_string, 16)
      atom_name = String.to_atom(String.downcase(name,:ascii))
      {atom_name, hex_int}
    end) |> Map.new
    # names = Enum.map(names_and_rgb, fn {name, _} -> String.to_atom(name) end)
    quote do
      @colors unquote(Macro.escape(colors))
      @names_and_rgb unquote(Macro.escape(names_and_rgb))
      def json() do
        @colors
      end
      def names() do
        Map.keys(@names_and_rgb)
      end
      def get_color_int(name) do
        Map.fetch!(@names_and_rgb, name)
      end
    end
  end
end
