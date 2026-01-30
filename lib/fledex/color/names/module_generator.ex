# Copyright 2023-2026, Matthias Reik <fledex@reik.org>
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
    %Macro.Env{file: path, module: caller_module} = __CALLER__
    base_path = Path.expand(Path.dirname(path))
    file_path = Path.expand(Path.dirname(path) <> "/" <> filename)

    if not String.starts_with?(file_path, base_path) do
      raise(
        ArgumentError,
        "Invalid file path, probably trying to move out of the module directory"
      )
    end

    converter = Keyword.fetch!(opts, :converter)
    opts = Keyword.drop(opts, [:filename, :converter, :fields])
    opts = Keyword.put_new(opts, :module, caller_module)

    create_color_functions_ast(
      file_path,
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

      @external_resource filename
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

      @impl Interface
      @doc delegate_to: {Interface, :is_color_name, 1}
      @doc guard: true
      defguard is_color_name(atom) when is_atom(atom) and is_map_key(@colors, atom)

      @impl Interface
      @doc delegate_to: {Interface, :colors, 0}
      @spec colors :: list(Types.color_struct_t())
      def colors do
        Map.values(@colors)
      end

      @impl Interface
      @doc delegate_to: {Interface, :names, 0}
      @spec names :: list(color_name_t)
      def names, do: Map.keys(@colors)

      @impl Interface
      @doc delegate_to: {Interface, :info, 2}
      def info(name, what \\ :hex)

      def info(name, what) when is_color_name(name) do
        @colors
        |> Map.get(name)
        |> ModuleGenerator.extract_property(what)
      end

      def info(_name, _what), do: nil

      @base16 16
      for {name, color} <- colors do
        @doc false
        @spec unquote(name)(Types.color_props_t()) :: Types.color_vals_t()
        def unquote(name)(what \\ :hex)

        @doc false
        def unquote(name)(what) when is_atom(what) and what not in unquote(fields) do
          info(unquote(name), what)
        end

        for field <- fields do
          @doc false
          def unquote(name)(unquote(field)), do: unquote(color[field])
        end

        @doc false
        @spec unquote(name)(Leds.t()) :: Leds.t()
        def unquote(name)(leds), do: leds |> Leds.light(unquote(color.hex))

        @doc false
        @spec unquote(name)(Leds.t(), opts :: keyword) :: Leds.t()
        def unquote(name)(leds, opts) do
          leds |> Leds.light(unquote(color.hex), opts)
        end
      end

      @doc false
      @spec filename :: String.t()
      def filename, do: hd(@external_resource)
    end
  end
end
