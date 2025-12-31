# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Color.Names.Wiki do
  @moduledoc ~S"""
  This module defines all the named colors specified on [Wikipedia](https://www.wikipedia.org/), which is a collection
  of various sources.
  See:
  * [List of colors: A–F](https://en.wikipedia.org/wiki/List_of_colors:_A%E2%80%93F)
  * [List of colors: G–M](https://en.wikipedia.org/wiki/List_of_colors:_G%E2%80%93M)
  * [List of colors: N–Z](https://en.wikipedia.org/wiki/List_of_colors:_N%E2%80%93Z)

  > #### Notes {: .info}
  >
  > * This module implements the `@behaviour` [`Fledex.Color.Names.Interface`](`m:Fledex.Color.Names.Interface`) (check it out for more details).
  > * Every color has it's own function as explained in `Fledex.Color.Names.Interface` and supports all of the classical options (`:all`, `:descriptive_name`, `:hex`, `:hsl`, `:hsv`, `:index`, `:name`, `:rgb`, `:source`, `:module`)
  > * A list of all available colors from this module can be found in the documentation under [Colors](colors.md#wiki).
  """

  alias Fledex.Color.Names.Wiki.Converter

  use Fledex.Color.Names.ModuleGenerator,
    filename: "wiki_colors.csv",
    converter: &Converter.converter/1,
    splitter_opts: [separator: ",", split_opts: [parts: 11]]
end
