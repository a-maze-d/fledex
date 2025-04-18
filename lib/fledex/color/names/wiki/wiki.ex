# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Color.Names.Wiki do
  @moduledoc ~S"""
  Do not use this module directly, but use Fledex.Color.Names instead
  """

  alias Fledex.Color.Names.WikiUtils

  @external_resource Path.dirname(__DIR__) <> "/wiki/wiki_colors.csv"

  use Fledex.Color.Names.Dsl,
    filename: @external_resource,
    pattern: ~r/^.*$/i,
    drop: 1,
    splitter_opts: [separator: ",", split_opts: [parts: 11]],
    converter: &WikiUtils.converter/1,
    module: __MODULE__

  def file do
    @external_resource
  end
end
