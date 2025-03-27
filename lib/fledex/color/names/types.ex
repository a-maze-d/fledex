# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.Types do
  # alias Fledex.Color.Names.NamesA2F
  # alias Fledex.Color.Names.NamesG2M
  # alias Fledex.Color.Names.NamesN2Z
  alias Fledex.Color.Names
  alias Fledex.Color.Types

  @typedoc """
  The allowed color names
  """
  @type color_names_t :: Names.color_names_t()
  # NamesA2F.color_names_t
  # | NamesG2M.color_names_t
  # | NamesN2Z.color_names_t

  @typedoc """
  The different properties that can be interrogated from a named color
  """
  @type color_props_t ::
          :all | :index | :name | :descriptive_name | :hex | :rgb | :hsl | :hsv | :source
  @typedoc """
  The structure of a named color with all it's attributes.
  """
  @type color_struct_t :: %{
          index: integer,
          name: color_names_t,
          descriptive_name: String.t(),
          hex: Types.colorint(),
          rgb: Types.rgb(),
          hsl: Types.hsl(),
          hsv: Types.hsv(),
          source: String.t(),
          module: module
        }
  @typedoc """
  The different values that can be returned when interrogating for some named color properties
  """
  @type color_vals_t :: Types.color_any() | color_struct_t | String.t()
end
