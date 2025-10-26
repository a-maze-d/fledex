# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.HSL do
  defstruct h: 0, s: 0, l: 0
  @type t :: %__MODULE__{h: 0..255, s: 0..255, l: 0..255}
end
