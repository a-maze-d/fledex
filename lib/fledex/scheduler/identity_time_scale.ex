# Copyright 2025, Matthias Reik <fledex@reik.org>
# Modified version of : https://github.com/SchedEx/SchedEx
#
# SPDX-License-Identifier: Apache-2.0
# SPDX-License-Identifier: MIT
defmodule Fledex.Scheduler.SchedEx.IdentityTimeScale do
  @moduledoc """
  The default module used to set the `time_scale`. Can be thought of as "normal time" where "now" is now and speedup is 1 (no speedup).
  """
  @behaviour Fledex.Scheduler.SchedEx.TimeScale

  alias Fledex.Scheduler.SchedEx.TimeScale

  @impl TimeScale
  def now(timezone) do
    DateTime.now(timezone) |> elem(1)
  end

  @impl TimeScale
  def speedup do
    1
  end
end
