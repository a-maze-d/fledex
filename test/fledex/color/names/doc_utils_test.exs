# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.DocUtilsTest do
  use ExUnit.Case

  alias Fledex.Color.Names.DocUtils

  describe "extract documentation" do
    test "can extract existing documenation" do
      assert DocUtils.extract_doc(DocUtils, :extract_doc, 3) =~
               "Extracts the docs from a function"
    end

    test "nil for non-existing function documenation" do
      assert DocUtils.extract_doc(DocUtils, :non_existent, 0) == nil
    end

    test "nil for non-existing module" do
      assert DocUtils.extract_doc(NonExisting, :non_existent, 0) == nil
    end
  end
end
