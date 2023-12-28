# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Kino.LivebookCase do
  use ExUnit.CaseTemplate

  import Kino.Test

  using do
    quote do
      import Kino.Test
    end
  end

  setup :configure_livebook_bridge
end
