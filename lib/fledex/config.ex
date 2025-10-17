# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Config do
  @moduledoc """
  > #### Caution {:.warning}
  >
  > Even though you can `use` this module several times, you might get unwanted
  > effects and change your `Fledex.Config.Data` unintentionally.
  > You really should just call `create_config/1` in this module only once.
  >
  > When you `use Fledex` you will also call `create_config/1`. In a `component` you
  > should not `use Fledex` but `import Fledex` and be explicit in your color selection.
  """

  require Logger

    # known color modules with their aliases
    @known_color_modules [
      {Fledex.Color.Names.Wiki, :core, :wiki},
      {Fledex.Color.Names.CSS, :core, :css},
      {Fledex.Color.Names.SVG, :core, :svg},
      # we intentionally do not include RAL colors as `:core`
      {Fledex.Color.Names.RAL, :optional, :ral}
    ]

  @doc """
  By using this module you configure the Fledex. Currently the only setting is to define
  the color modules to be used through the `:colors` option.

  > #### Caution {:.warning}
  >
  > This will create the `Fledex.Config.Data` module. If you `use` this
  > module several times, previous definition will be replaced. This could lead
  > to unexpected behaviors.
  >
  > See also `create_config_ast/1` that is used internally for more details on what
  > is happening

  ### Options:
  * `:colors`: You can specify a single color module, a list of color modules, or one of the special specifiers (`:default`, `:all`, `:none`, `nil`). When you specify a color module you can do so either through it's fully qualified module name (and thereby even
  load color modules that Fledex doesn't know about) or through its shortcut name (see `Fledex.Config.known_color_modules/0`)

  ### Special specifiers:
  * `:all`: All known color modules will be loaded. Be careful, because there are A LOT of color names, probably more than what you really need
  * `:default`: This will load the core modules (see `Fledex.Config.known_color_modules/0`). If no `:colors` option is specified then that's also the set that will be loaded.
  * `:none`: No color will be loaded (still the `Fledex.Color.Names.Config` will be created. Compare this with `nil`)
  * `nil`: This is similar to `:none` except that the `Fledex.Color.Names.Config` will not be created, and if it exists will be deleted.
  """
  @spec __using__(keyword) :: Macro.t()
  defmacro __using__(opts) do
    create_config_ast(opts)
  end

  @doc """
  This function will create an AST that:
    1. defines the `Fledex.Config.Data` which is used by this module
    2. creates the necessary color module imports that are being defined

  You can use this function directly, but you probably want to use the
  macro `__using__/1` (through `use Fledex.Config, opts`)
  """
  @spec create_config_ast(keyword) :: Macro.t()
  def create_config_ast(opts) do
    colors = Keyword.get(opts, :colors, :default)

    if colors == nil do
      quote do
        Elixir.Fledex.Config.cleanup_old_config()
      end
    else
      # we get an AST, so we need to convert it back to a list of atoms and module names
      modules_and_colors =
        colors
        |> Macro.prewalk(&Macro.expand(&1, __ENV__))
        |> find_modules_with_names()

      ast = create_imports_ast(modules_and_colors)

      quote bind_quoted: [colors: modules_and_colors, ast: ast] do
        Macro.escape(ast)
        Elixir.Fledex.Config.cleanup_old_config()

        defmodule Elixir.Fledex.Config.Data do
          @moduledoc """
          This module is an implementation detail from `Fledex.Color.Names` and therefore
          should not be used directly. use `Fledex.Config.configured_color_modules/0` instead
          """
          @colors colors

          @doc false
          @spec colors :: list({module, list(atom)})
          def colors do
            @colors
          end
        end
      end
    end
  end

  @doc """
  Check whether we have defined a configuration.

  If not, all function calls in this module will succeed,
  but will only contain defaults (probably quite empty results)
  """
  @spec exists? :: boolean
  def exists?() do
    Code.loaded?(Fledex.Config.Data)
  end

  @doc """
  Returns a list with the known color name modules (known to Fledex)

  Fledex is configured with a set of color name modules that can be retrieved through this function. A list is returned with a tuple consisting of of:

  * `module`: The color name module
  * `type`: Whether it's a `:core` color or an `:optional` color. The former will get loaded as one of the default colors
  * `shortcut_name`: an `atom` name through which you can reference this module

  It should be noted that the order is important in the case of name conflicts. Color name definitions from earlier modules take precedence.

  Example:
  * Given `ModuleA` defines `:green` as `0x00FF00`
  * Given `ModuleB` defines `:green` as `0x00AA00`
  * If `ModuleA` is specied BEFORE `ModuleB` then `:green` will be defined as `0x00FF00`
  * If `ModuleA` is specified AFTER `ModuleB` then `:green` will be defined as `0x00AA00`
  """
  @spec known_color_modules :: list({module, type :: :core | :optional, shutcut_name :: atom})
  def known_color_modules do
    @known_color_modules
  end

  @doc """
  Get the list of modules and their (non-overlapping) colors that are currently configured
  """
  @spec configured_color_modules :: list({module, list(atom)})
  def configured_color_modules do
    case exists?() do
      true ->
        # credo:disable-for-next-line
        apply(Fledex.Config.Data, :colors, [])

      false ->
        []
    end
  end

  # MARK: private helper functions

  # This function takes either a module, an atom or a list of those,
  # resolves atoms to their corresponding modules, retrieves all
  # the color names by calling `module.names()` ensuring later modules
  # do not override previous names in case of conflict, and returns
  # a list of modules and their non-conflicting names.
  @spec find_modules_with_names(module | atom | list(module | atom) | nil) ::
          list({module, list(atom)})
  defp find_modules_with_names([]), do: []
  defp find_modules_with_names(opt) when is_atom(opt), do: find_modules_with_names([opt])
  defp find_modules_with_names([:none]), do: find_modules_with_names([])

  defp find_modules_with_names([:all]) do
    Enum.map(@known_color_modules, fn elem -> elem(elem, 0) end)
    |> find_modules_with_names()
  end

  defp find_modules_with_names([:default]) do
    Enum.filter(@known_color_modules, fn {_mod, type, _name} -> type == :core end)
    |> Enum.map(fn elem -> elem(elem, 0) end)
    |> find_modules_with_names()
  end

  defp find_modules_with_names(color_names) when is_list(color_names) do
    color_names
    # |> Enum.reverse()
    |> translate_names2modules()
    |> diff_names_between_modules()
  end

  @spec translate_names2modules(list(module | atom)) :: list(module)
  defp translate_names2modules(names) do
    Enum.reduce(names, [], fn color_name, acc ->
      find_module_name(color_name, acc)
    end)
    |> Enum.reverse()
  end

  @spec find_module_name(atom | module, list(module)) :: list(module)
  defp find_module_name(color_name, acc) do
    case Enum.find(@known_color_modules, fn {_module, _type, name} -> name == color_name end) do
      {module, _type, _name} ->
        # we translate from an atom to a module
        [module | acc]

      nil ->
        # no translation, maybe we got a names module
        if loadable?(color_name) do
          [color_name | acc]
        else
          # we have no idea what we got so we will ignore it
          Logger.warning("""
          Not a known color name. Either an atom (with appropriate mapping)
          or a module (implementing the Fledex.ColorNames behavior) is expected.
          I found instead: "#{inspect(color_name)}", and we will ignore it
          """)

          acc
        end
    end
  end

  @spec loadable?(module) :: boolean
  defp loadable?(color_name) do
    Code.ensure_loaded?(color_name) and function_exported?(color_name, :names, 0)
  end

  @spec diff_names_between_modules(list(module)) :: list({module, list(atom)})
  defp diff_names_between_modules(modules) do
    Enum.reduce(modules, {[], MapSet.new()}, fn module, {mods, known} ->
      only = MapSet.difference(MapSet.new(module.names()), known)
      {[{module, MapSet.to_list(only)} | mods], MapSet.union(known, only)}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  @spec create_imports_ast(list({module, list(atom)})) :: Macro.t()
  def create_imports_ast(modules_and_colors) do
    modules_and_colors
    |> modules_with_only()
    |> Enum.map(&import_color_module/1)
  end

  # Convert a list of module-"color names" to a list that
  # can be used to import modules (i.e. with the correct arity)
  @spec modules_with_only(list({module, list(atom)})) :: list({module, list({atom, 0 | 1 | 2})})
  defp modules_with_only(modules_with_colors) do
    # each name has a function with arity 1 and 2
    Enum.map(modules_with_colors, fn {module, names} ->
      {module,
       Enum.flat_map(names, fn only ->
         [{only, 0}, {only, 1}, {only, 2}]
       end)}
    end)
  end

  @spec import_color_module({module, list(atom)}) :: Macro.t()
  defp import_color_module({module, only}) do
    quote do
      import unquote(module), only: unquote(only)
    end
  end

  @doc """
  This function will cleanup a previously defined
  config. It's safe to call this funciton even if none has
  been defined.

  > ##### Note {:.info}
  >
  > Proably you don't want to call this function and just redefine
  > your configuration to your likings
  """
  @spec cleanup_old_config() :: :ok
  def cleanup_old_config() do
    if exists?() do
      # `Code` does not expose those functions, so we need to use Erlang version.
      :code.purge(Fledex.Config.Data)
      :code.delete(Fledex.Config.Data)
    end

    :ok
  end
end
