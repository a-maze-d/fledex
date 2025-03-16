# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.Guards do
  require Fledex.Color.Names.NamesWikiA2H, as: NamesWikiA2H
  require Fledex.Color.Names.NamesWikiI2O, as: NamesWikiI2O
  require Fledex.Color.Names.NamesWikiP2Z, as: NamesWikiP2Z

  @doc """
    Check whether the atom is a valid color name
  """
  @doc guard: true
  defguard is_color_name(atom)
           when NamesWikiA2H.is_color_name(atom) or
                  NamesWikiI2O.is_color_name(atom) or
                  NamesWikiP2Z.is_color_name(atom)
end
