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

  > #### Note {: .info}
  >
  > This module implements the `Fledex.Color.Names.Interface` behaviour.
  """

  alias Fledex.Color.Names.WikiUtils

  @external_resource Path.dirname(__DIR__) <> "/wiki/wiki_colors.csv"

  use Fledex.Color.Names.ModuleGenerator,
    filename: @external_resource,
    pattern: ~r/^.*$/i,
    drop: 1,
    splitter_opts: [separator: ",", split_opts: [parts: 11]],
    converter: &WikiUtils.converter/1,
    module: __MODULE__

  @doc false
  def file do
    @external_resource
  end
end
