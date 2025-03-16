# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.Dsl do
  defmacro __using__(opts) do
    pattern = Keyword.get(opts, :pattern, ~r/^.*$/i)
    create_color_functions(pattern)
  end

  def create_color_functions(pattern) do
    quote unquote: false, bind_quoted: [pattern: pattern] do
      @moduledoc ~S"""
      Do not use this module directly, but use Fledex.Color.Names instead
      """

      alias Fledex.Color.Names.LoadUtils
      alias Fledex.Color.Names.Types
      alias Fledex.Leds

      @external_resource Fledex.Color.Names.LoadUtils.names_file()
      colors = LoadUtils.load_color_file(@external_resource, pattern)

      @colors colors
      @color_names Enum.map(@colors, fn %{name: name} = _colorinfo -> name end)
      @typedoc """
      The allowed color names
      """
      @type color_names_t ::
              unquote(
                @color_names
                |> Enum.map_join(" | ", &inspect/1)
                |> Code.string_to_quoted!()
              )

      @doc ~S"""
      Check whether the atom is a valid color name
      """
      @doc guard: true
      defguard is_color_name(atom) when atom in @color_names

      @doc ~S"""
      Get all the data about the predefined colors
      """
      @spec colors :: list(Types.color_struct_t())
      def colors do
        @colors
      end

      @doc ~S"""
      Get a list of all the predefined color (atom) names.

      The name can be used to either retrieve the info by calling `info/2` or by calling the function with that
      name (see also the description at the top and take a look at this [example livebook](3b_fledex_more_about_colors.livemd))
      """
      @spec names :: list(color_names_t)
      def names, do: @color_names

      # @doc ~S"""
      # Retrieve information about the color with the given name
      # """
      # @spec info(name :: Types.color_names_t(), what :: Types.color_props_t()) :: Types.color_vals_t()
      # def info(name, what \\ :hex)
      # def info(name, what) when is_color_name(name), do: apply(__MODULE__, name, [what])
      # def info(_name, _what), do: nil

      @base16 16
      for color <- colors do
        name = color.name
        {r, g, b} = color.rgb

        hex =
          color.hex
          |> Integer.to_string(@base16)
          |> String.pad_leading(6, "0")

        @doc """
        <div style="width: 25px; height: 25px; display: inline-block; background-color: ##{hex}; border: 1px solid black"></div>

        Defines the color rgb(#{r}, #{g}, #{b}).
        """
        @doc color_name: true
        @spec unquote(name)(Types.color_props_t()) :: Types.color_vals_t()
        def unquote(name)(what \\ :hex)
        def unquote(name)(:all), do: unquote(Macro.escape(color))
        def unquote(name)(:index), do: unquote(Macro.escape(color)).index
        def unquote(name)(:name), do: unquote(Macro.escape(color)).name
        def unquote(name)(:rgb), do: unquote(Macro.escape(color)).rgb
        def unquote(name)(:hex), do: unquote(Macro.escape(color)).hex
        def unquote(name)(:hsv), do: unquote(Macro.escape(color)).hsv
        def unquote(name)(:hsl), do: unquote(Macro.escape(color)).hsl
        def unquote(name)(:descriptive_name), do: unquote(Macro.escape(color)).descriptive_name
        def unquote(name)(:source), do: unquote(Macro.escape(color)).source
        @spec unquote(name)(Leds.t()) :: Leds.t()
        def unquote(name)(leds), do: leds |> Leds.light(unquote(Macro.escape(color)).hex)
        @doc false
        @spec unquote(name)(Leds.t(), offset :: non_neg_integer) :: Leds.t()
        def unquote(name)(leds, offset),
          do: leds |> Leds.light(unquote(Macro.escape(color)).hex, offset)
      end
    end
  end
end
