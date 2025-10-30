# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Color.Names.Wiki do
  @moduledoc ~S"""
  This module defines all the named colors specified on wikipedia, which is a collection
  of various sources.
  See:
  * https://en.wikipedia.org/wiki/List_of_colors:_A%E2%80%93F
  * https://en.wikipedia.org/wiki/List_of_colors:_G%E2%80%93M
  * https://en.wikipedia.org/wiki/List_of_colors:_N%E2%80%93Z

  > #### Notes {: .info}
  >
  > * This module implements the `@behaviour` [`Fledex.Color.Names.Interface`](`m:Fledex.Color.Names.Interface`) (check it out for more details).
  > * Every color has it's own function as explained in `Fledex.Color.Names.Interface` and supports all of the classical options (`:all`, `:descriptive_name`, `:hex`, `:hsl`, `:hsv`, `:index`, `:name`, `:rgb`, `:source`, `:module`)
  > * A list of all available colors from this module can be found in the documentation under [Colors](colors.md#wiki).
  """

  alias Fledex.Color.Names.WikiUtils

  use Fledex.Color.Names.ModuleGenerator,
    filename: WikiUtils.file_name(),
    converter: &WikiUtils.converter/1,
    splitter_opts: [separator: ",", split_opts: [parts: 11]]
end
