# Copyright 2025, Matthias Reik <fledex@reik.org>
# Modified version of : https://github.com/SchedEx/SchedEx
#
# SPDX-License-Identifier: Apache-2.0
# SPDX-License-Identifier: MIT
defmodule Fledex.Scheduler.SchedEx.TimeScale do
  @moduledoc """
  Constrols time in Fledex.Scheduler.SchedEx, often used to speed up test runs, or implement
  custom timing loops.

  Default implementation is `Fledex.Scheduler.SchedEx.IdentityTimeScale`.
  """

  @doc """
  Must return the current time in the specified timezone.
  """
  @callback now(Calendar.time_zone()) :: DateTime.t()

  @doc """
  Must returns a float factor to speed up delays by.
  """
  @callback speedup() :: number
end
