# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.Dsl do
  alias Fledex.Color.Names.LoadUtils

  defmacro __using__(opts) do
    filename = Keyword.fetch!(opts, :filename)
    pattern = Keyword.fetch!(opts, :pattern)
    drop = Keyword.fetch!(opts, :drop)
    splitter_opts = Keyword.fetch!(opts, :splitter_opts)
    converter = Keyword.fetch!(opts, :converter)
    module = Keyword.get(opts, :module, :unknown)

    create_color_functions(
      filename,
      pattern,
      drop,
      splitter_opts,
      converter,
      module
    )
  end

  # credo:disable-for-next-line
  def create_color_functions(
        filename,
        pattern,
        drop,
        splitter_opts,
        converter,
        module
      ) do
    quote unquote: false,
          bind_quoted: [
            pattern: pattern,
            filename: filename,
            drop: drop,
            splitter_opts: splitter_opts,
            converter: converter,
            module: module
          ] do
      alias Fledex.Color.Names.Types
      alias Fledex.Leds

      colors =
        LoadUtils.load_color_file(
          filename,
          pattern,
          drop,
          splitter_opts,
          converter,
          module
        )

      @colors colors
      @color_names Map.keys(@colors)
      @typedoc """
      The allowed color names
      """
      @type color_names_t ::
              unquote(
                Map.keys(@colors)
                |> Enum.map_join(" | ", &inspect/1)
                |> Code.string_to_quoted!()
              )

      @doc ~S"""
      Check whether the atom is a valid color name
      """
      @doc guard: true
      defguard is_color_name(atom) when is_atom(atom) and is_map_key(@colors, atom)

      @doc ~S"""
      Get all the data about the predefined colors
      """
      @spec colors :: list(Types.color_struct_t())
      def colors do
        # TODO: maybe changes it to a map?
        Map.values(@colors)
      end

      @doc ~S"""
      Get a list of all the predefined color (atom) names.

      The name can be used to either retrieve the info by calling `info/2` or by calling the function with that
      name (see also the description at the top and take a look at this [example livebook](3b_fledex_more_about_colors.livemd))
      """
      @spec names :: list(color_names_t)
      def names, do: Map.keys(@colors)

      @base16 16
      for {name, color} <- colors do
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
        def unquote(name)(:module), do: unquote(Macro.escape(color)).module
        @spec unquote(name)(Leds.t()) :: Leds.t()
        def unquote(name)(leds), do: leds |> Leds.light(unquote(Macro.escape(color)).hex)
        @doc false
        @spec unquote(name)(Leds.t(), opts :: keyword) :: Leds.t()
        def unquote(name)(leds, opts),
          do: leds |> Leds.light(unquote(Macro.escape(color)).hex, opts)
      end
    end
  end
end
