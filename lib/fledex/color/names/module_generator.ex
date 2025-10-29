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
      converter: &MyColorModule.Utils.converter/1,
      splitter_opts: [separator: ",", split_opts: [parts: 11]],
  end
  ```
  The filename and the converter function are mandatory. The converter function needs to return a `t:Fledex.Color.Names.Types.color_struct_t` struct. You can find some useful utility functions that help you in the conversion in `Fledex.Color.Names.LoadUtils`.

  In addition a set of options can be specified. Most of them are passed on to `Fledex.Color.Names.LoadUtils.load_color_file/3`.

  Apart from those options, you can also specify the option `:fields` that specifies for which fields a function should be created (default: `[:hex]`). Thus, by default we wuld create for the color `:almond` a function `almond(:hex)` that directly returns the hex-color instead of going through some indirections.

  It should be noted that, if no `:module` option is specified, the `__CALLER__` module
  name will be configured.
  """

  alias Fledex.Color.Names.LoadUtils
  alias Fledex.Color.Names.Types

  @doc """
    Create a color names module by `use Fledex.Color.Names.ModuleGenerator`.

    See the module description to see how to use it
  """
  defmacro __using__(opts) do
    filename = Keyword.fetch!(opts, :filename)
    converter = Keyword.fetch!(opts, :converter)
    opts = Keyword.drop(opts, [:filename, :converter, :fields])
    %{module: caller_module} = __CALLER__
    opts = Keyword.put_new(opts, :module, caller_module)

    create_color_functions_ast(
      filename,
      converter,
      opts
    )
  end

  @doc false
  @spec extract_property(Types.color_struct_t(), atom) :: any
  def extract_property(color, :all), do: color
  def extract_property(color, what), do: Map.get(color, what)

  @doc false
  # credo:disable-for-lines:110
  @spec create_color_functions_ast(
          String.t(),
          ([String.t() | integer] -> Types.color_struct_t()),
          keyword
        ) :: Macro.t()
  def create_color_functions_ast(
        filename,
        converter,
        opts
      ) do
    fields = Keyword.get(opts, :fields, [:hex])
    opts = Keyword.drop(opts, [:fields])

    quote unquote: false,
          bind_quoted: [
            filename: filename,
            converter: converter,
            opts: opts,
            fields: fields
          ] do
      @behaviour Fledex.Color.Names.Interface

      alias Fledex.Color.Names.Interface
      alias Fledex.Color.Names.ModuleGenerator
      alias Fledex.Color.Names.Types
      alias Fledex.Leds

      colors = LoadUtils.load_color_file(filename, converter, opts)

      @colors colors
      @color_names Map.keys(@colors)
      # @typedoc """
      # The allowed color names
      # """
      @typedoc false
      @type color_name_t ::
              unquote(
                Map.keys(@colors)
                |> Enum.map_join(" | ", &inspect/1)
                |> Code.string_to_quoted!()
              )

      # @doc ~S"""
      # Check whether the atom is a valid color name
      # """
      @impl Interface
      # @doc guard: true
      @doc false
      defguard is_color_name(atom) when is_atom(atom) and is_map_key(@colors, atom)

      # @doc ~S"""
      # Get all the data about the predefined colors
      # """
      @doc false
      @impl Interface
      @spec colors :: list(Types.color_struct_t())
      def colors do
        Map.values(@colors)
      end

      # @doc ~S"""
      # Get a list of all the predefined color (atom) names.

      # The name can be used to either retrieve the info by calling `info/2` or by calling the function with that name (see also the description at the top and take a look at this [example livebook](3b_fledex_everything_about_colors.livemd))
      # """
      @doc false
      @impl Interface
      @spec names :: list(color_name_t)
      def names, do: Map.keys(@colors)

      # @standard_fields fields
      # @doc """
      # Retrieve information about the color with the given name
      # """
      @doc false
      @impl Interface
      def info(name, what \\ :hex)

      def info(name, what) when is_color_name(name) do
        @colors
        |> Map.get(name)
        |> ModuleGenerator.extract_property(what)
      end

      def info(_name, _what), do: nil

      @base16 16
      for {name, color} <- colors do
        # {r, g, b} = color.rgb

        # hex =
        #   color.hex
        #   |> Integer.to_string(@base16)
        #   |> String.pad_leading(6, "0")

        # @doc """
        # Defines the color rgb(#{r}, #{g}, #{b}).

        # <div style="width: 25px; height: 25px; display: inline-block; background-color: ##{hex}; border: 1px solid black"></div>
        # """
        # @doc color_name: true
        @doc false
        @spec unquote(name)(Types.color_props_t()) :: Types.color_vals_t()
        def unquote(name)(what \\ :hex)

        def unquote(name)(what) when is_atom(what) and what not in unquote(fields) do
          info(unquote(name), what)
        end

        for field <- fields do
          def unquote(name)(unquote(field)), do: unquote(Macro.escape(color))[unquote(field)]
        end

        @spec unquote(name)(Leds.t()) :: Leds.t()
        def unquote(name)(leds), do: leds |> Leds.light(unquote(Macro.escape(color)).hex)
        @doc false
        @spec unquote(name)(Leds.t(), opts :: keyword) :: Leds.t()
        def unquote(name)(leds, opts) do
          leds |> Leds.light(unquote(Macro.escape(color)).hex, opts)
        end
      end
    end
  end
end
