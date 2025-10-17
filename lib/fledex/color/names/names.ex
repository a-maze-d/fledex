# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Elixir.Fledex.Color.Names do
  @moduledoc """
  This module is a bridge between color name modules aond the `Fledex.Color`
  protocol. It uses the `Fledex.Config` to know about the configured colors
  """

  alias Fledex.Color.Names.Types
  alias Fledex.Config

  # @doc """
  # By using this module you configure the #{__MODULE__} for a set of colors as
  # specified in the `:colors` option.

  # > #### Caution {:.warning}
  # >
  # > This will create the `Fledex.Config.Data` module. If you `use` this
  # > module several times, previous definition will be replaced. This could lead
  # > to unexpected behaviors.

  # ### Options:
  # * `:colors`: You can specify a single color module, a list of color modules, or one of the special specifiers (`:default`, `:all`, `:none`, `nil`). When you specify a color module you can do so either through it's fully qualified module name (and thereby even
  # load color modules that Fledex doesn't know about) or through its shortcut name (see `Fledex.Config.modules/0`)

  # ### Special specifiers:
  # * `:all`: All known color modules will be loaded. Be careful, because there are A LOT of color names, probably more than what you really need
  # * `:default`: This will load the core modules (see `Fledex.Config.modules/0`). If no `:colors` option is specified then that's also the set that will be loaded.
  # * `:none`: No color will be loaded (still the `Fledex.Color.Names.Config` will be created. Compare this with `nil`)
  # * `nil`: This is similar to `:none` except that the `Fledex.Color.Names.Config` will not be created, and if it exists will be deleted.
  # """
  # @spec __using__(keyword) :: Macro.t()
  # defmacro __using__(opts) do
  #   Fledex.Config.create_config_ast(opts)
  # end

  @doc """
  Checks whether the argument is a valid color name.

  For specific color modules this returns true only if the atom is a valid color
  name. For this facade module all atoms could be a valid color name. Thus, we
  loosen the definition here.
  """
  @doc guard: true
  defguard is_color_name(atom) when is_atom(atom)

  @doc """
  Get a detailed list of all the colors that have been configured
  """
  @spec colors :: list(Types.color_struct_t())
  def colors do
    Enum.flat_map(Config.configured_color_modules(), fn {module, color_names} ->
      Enum.filter(module.colors(), fn color ->
        color[:name] in color_names
      end)
    end)
    |> Enum.sort_by(& &1, fn left, right -> left.name < right.name end)
  end

  @doc """
  get a list of all the color names that are currently configured.

  Contrary to normal color modules, you can't use the color name atom as a
  function name. You still can retrieve the information through  `info/1`
  and `info/2`. Alternatively you need to ensure that the configured color
  modules are imported.

  > #### Caution {:.warning}
  >
  > When importing color modules, you have to be careful to only import those
  > functions that do not overlap. You can call `Fledex.Config.configured_color_modules/0` to get
  > the list of modules and the colors that should be imported.
  """
  @spec names :: list(Types.color_name_t())
  def names do
    Enum.flat_map(Config.configured_color_modules(), fn {_module, colors} -> colors end)
  end

  @doc """
  Retrieve information about the color with the given name

  See `m:Fledex.Color.Names.Interface` for more details
  """
  @spec info(name :: atom, what :: Types.color_props_t()) :: nil | Types.color_vals_t()
  def info(name, what \\ :hex)

  def info(name, what) do
    find_module_with_names(name)
    |> get_color_from_module(name, what)
  end

  # MARK: private utility functions
  @spec find_module_with_names(atom) :: {module, list(atom)}
  defp find_module_with_names(name) do
    Enum.find(Config.configured_color_modules(), {nil, []}, fn {_module, colors} ->
      name in colors
    end)
    |> elem(0)
  end

  @spec get_color_from_module(module | nil, atom, atom) :: nil | Types.color_vals_t()
  defp get_color_from_module(nil, _name, _what), do: nil

  defp get_color_from_module(module, name, what) do
    module.info(name, what)
  end
end
