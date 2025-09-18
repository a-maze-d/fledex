# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.Interface do
  @moduledoc """
  This module defines the standard interface (behaviour) for color name modules
  which they should implement.
  """

  alias Fledex.Color.Names.Types

  @doc ~S"""
  Check whether the atom is a valid color name
  """
  @doc guard: true
  @macrocallback is_color_name(atom) :: Macro.t()

  @doc ~S"""
  Get all the data about the predefined colors
  """
  @callback colors :: list(Types.color_struct_t())

  @doc ~S"""
  Get a list of all the predefined color (atom) names.

  The name can be used to either retrieve the info by calling `info/2` or by calling the function with that
  name (see also the description at the top and take a look at this [example
  livebook](3b_fledex_everything_about_colors.livemd))
  """
  @callback names :: list(atom)

  @doc """
  Retrieve information about the color with the given name
  """
  @callback info(name :: atom, what :: Types.color_props_t()) :: Types.color_vals_t()
end
