# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.Utils do
  require Logger

  # known color modules with their aliases
  @modules [
    {Fledex.Color.Names.Wiki, :core, :wiki},
    {Fledex.Color.Names.CSS, :core, :css},
    {Fledex.Color.Names.SVG, :core, :svg},
    # we intentionally do not include RAL colors as `:core`
    {Fledex.Color.Names.RAL, :optional, :ral}
  ]

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
  @spec modules :: list({module, type :: :core | :optional, shutcut_name :: atom})
  def modules do
    @modules
  end

  @doc """
  This function takes either a module, an atom or a list of those,
  resolves atoms to their corresponding modules, retrieves all
  the color names by calling `module.names()` ensuring later modules
  do not override previous names in case of conflict, and returns
  a list of modules and their non-conflicting names.
  """
  @spec find_modules_with_names(module | atom | list(module | atom) | nil) ::
          list({module, list(atom)})
  def find_modules_with_names([]), do: []
  def find_modules_with_names(opt) when is_atom(opt), do: find_modules_with_names([opt])
  def find_modules_with_names([:none]), do: find_modules_with_names([])

  def find_modules_with_names([:all]) do
    Enum.map(@modules, fn elem -> elem(elem, 0) end)
    |> find_modules_with_names()
  end

  def find_modules_with_names([:default]) do
    Enum.filter(@modules, fn {_mod, type, _name} -> type == :core end)
    |> Enum.map(fn elem -> elem(elem, 0) end)
    |> find_modules_with_names()
  end

  def find_modules_with_names(color_names) when is_list(color_names) do
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
    case Enum.find(@modules, fn {_module, _type, name} -> name == color_name end) do
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

  @spec import_color_module({module, list(atom)}) :: Macro.t()
  defp import_color_module({module, only}) do
    quote do
      import unquote(module), only: unquote(only)
    end
  end

  def create_imports_ast(modules_and_colors) do
    modules_with_only(modules_and_colors)
    |> Enum.map(&import_color_module/1)
  end

  # @doc """
  # Convert a list of module-only list to a list that
  # can be used to import modules
  # """
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
end
