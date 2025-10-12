# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.Types do
  alias Fledex.Color.Types

  @typedoc """
  any atom could be a valid color name
  """
  @type color_name_t :: atom

  @typedoc """
  The different properties that can be interrogated from a named color
  """
  @type color_props_t ::
          :all | :index | :name | :descriptive_name | :hex | :rgb | :hsl | :hsv | :source
  @typedoc """
  The structure of a named color with all it's attributes.
  """
  @type color_struct_t :: %{
          optional(atom) => any(),
          index: integer,
          name: color_name_t,
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
