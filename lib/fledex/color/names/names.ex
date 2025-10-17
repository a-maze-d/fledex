# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names do
  @moduledoc """
  This module is a bridge between color name modules and the `Fledex.Color`
  protocol. It uses the `Fledex.Config` to know about the configured colors
  """
  @behaviour Fledex.Color.Names.Interface

  alias Fledex.Color.Names.Types
  alias Fledex.Config

  @doc """
  Checks whether the argument is a valid color name.

  For specific color modules this returns true only if the atom is a valid color
  name. For this facade module all atoms could be a valid color name. Thus, we
  loosen the definition here.
  """
  @doc guard: true
  @impl true
  defguard is_color_name(atom) when is_atom(atom)

  @doc """
  Get a detailed list of all the colors that have been configured
  """
  @spec colors :: list(Types.color_struct_t())
  @impl true
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
  @impl true
  def names do
    Enum.flat_map(Config.configured_color_modules(), fn {_module, colors} -> colors end)
  end

  @doc """
  Retrieve information about the color with the given name

  See `m:Fledex.Color.Names.Interface` for more details
  """
  @impl true
  @spec info(name :: atom, what :: atom) :: nil | Types.color_vals_t() | any()
  def info(name, what \\ :hex)

  def info(name, what) when is_atom(name) and is_atom(what) do
    find_module_with_name(name)
    |> get_color_from_module(name, what)
  end
  def info(_name, _what), do: nil

  # MARK: private utility functions
  @spec find_module_with_name(atom) :: module | nil
  defp find_module_with_name(name) do
    Enum.find(Config.configured_color_modules(), {nil, []}, fn {_module, colors} ->
      name in colors
    end)
    |> elem(0)
  end

  @spec get_color_from_module(module | nil, atom, atom) :: nil | Types.color_vals_t() | any()
  defp get_color_from_module(nil, _name, _what), do: nil

  defp get_color_from_module(module, name, what) do
    module.info(name, what)
  end
end
