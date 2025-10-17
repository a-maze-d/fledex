# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.ModuleGenerator do
  @moduledoc """
  This module allows to easily create color name modules (implementing the
  `Fledex.Color.Names.Interface` behaviour) by simply using this module. Use
  it in the following way:

  ```elixir
  defmodule MyColorModule do
    # we point to our csv file that defines the colors
    @external_resource Path.dirname(__DIR__) <> "/my_colors.csv"

    use Fledex.Color.Names.ModuleGenerator,
      filename: @external_resource,
      pattern: ~r/^.*$/i,
      drop: 1,
      splitter_opts: [separator: ",", split_opts: [parts: 11]],
      converter: &MyColorModule.Utils.converter/1,
      module: __MODULE__
  end
  ```

  The converter function needs to return a `t:Fledex.Color.Names.Types.color_struct_t`
  struct. You can find some useful utility functions that help you in the conversion in
  `Fledex.Color.Names.LoadUtils`.
  """
  alias Fledex.Color.Names.LoadUtils

  defmacro __using__(opts) do
    filename = Keyword.fetch!(opts, :filename)
    pattern = Keyword.fetch!(opts, :pattern)
    drop = Keyword.fetch!(opts, :drop)
    splitter_opts = Keyword.fetch!(opts, :splitter_opts)
    converter = Keyword.fetch!(opts, :converter)
    module = Keyword.get(opts, :module, :unknown)

    fields =
      Keyword.get(opts, :fields, [
        :index,
        :name,
        :descriptive_name,
        :hex,
        :rgb,
        :hsl,
        :hsv,
        :source,
        :module
      ])

    create_color_functions(
      filename,
      pattern,
      drop,
      splitter_opts,
      converter,
      module,
      fields
    )
  end

  @doc false
  # credo:disable-for-next-line
  def create_color_functions(
        filename,
        pattern,
        drop,
        splitter_opts,
        converter,
        module,
        fields
      ) do
    quote unquote: false,
          bind_quoted: [
            pattern: pattern,
            filename: filename,
            drop: drop,
            splitter_opts: splitter_opts,
            converter: converter,
            module: module,
            fields: fields
          ] do
      @behaviour Fledex.Color.Names.Interface

      alias Fledex.Color.Names.Interface
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
      @type color_name_t ::
              unquote(
                Map.keys(@colors)
                |> Enum.map_join(" | ", &inspect/1)
                |> Code.string_to_quoted!()
              )

      @doc ~S"""
      Check whether the atom is a valid color name
      """
      @impl Interface
      @doc guard: true
      defguard is_color_name(atom) when is_atom(atom) and is_map_key(@colors, atom)

      @doc ~S"""
      Get all the data about the predefined colors
      """
      @impl Interface
      @spec colors :: list(Types.color_struct_t())
      def colors do
        Map.values(@colors)
      end

      @doc ~S"""
      Get a list of all the predefined color (atom) names.

      The name can be used to either retrieve the info by calling `info/2` or by calling the function with that
      name (see also the description at the top and take a look at this [example
      livebook](3b_fledex_everything_about_colors.livemd))
      """
      @impl Interface
      @spec names :: list(color_name_t)
      def names, do: Map.keys(@colors)

      @standard_fields fields
      @doc """
      Retrieve information about the color with the given name
      """
      @impl Interface
      def info(name, what \\ :hex)

      def info(name, what) do
        case {function_exported?(__MODULE__, name, 1), what in [:all | @standard_fields]} do
          {true, true} -> apply(__MODULE__, name, [what])
          {true, false} -> apply(__MODULE__, name, [:all]) |> Map.get(what, nil)
          _other -> nil
        end
      end

      @base16 16
      for {name, color} <- colors do
        {r, g, b} = color.rgb

        hex =
          color.hex
          |> Integer.to_string(@base16)
          |> String.pad_leading(6, "0")

        @doc """
        Defines the color rgb(#{r}, #{g}, #{b}).

        <div style="width: 25px; height: 25px; display: inline-block; background-color: ##{hex}; border: 1px solid black"></div>
        """
        @doc color_name: true
        @spec unquote(name)(Types.color_props_t()) :: Types.color_vals_t()
        def unquote(name)(what \\ :hex)
        def unquote(name)(:all), do: unquote(Macro.escape(color))

        for field <- fields do
          def unquote(name)(unquote(field)), do: unquote(Macro.escape(color))[unquote(field)]
        end

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
