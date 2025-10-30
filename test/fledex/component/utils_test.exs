# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Component.UtilsTest do
  use ExUnit.Case, async: true
  alias Fledex.Component.Utils

  test "create_name" do
    assert Utils.create_name(:name, :helper) == :name_helper
  end
end
