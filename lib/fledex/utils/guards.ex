# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Utils.Guards do
  @moduledoc """
    This module collects all useful guards. If you want to use one of them
    you need to `import` this module.
  """

  @doc """
    This guard checks whether the value is within the given range.
    Notes:

      * The lower bound is excluded (except if `inverse_bounds` is true)
      * The upper bound is included (except if `inverse_bounds` is true)
      * This guard is not fully tested, so be careful when using that it works for you.
  """
  # @spec is_in_range(integer, boolean, integer, integer) :: boolean
  defguard is_in_range(value, inverse_bounds, min, max)
           when is_integer(value) and
                  ((inverse_bounds and value + 1 > min and value + 1 <= max) or
                     (not inverse_bounds and value > min and value <= max))
end
