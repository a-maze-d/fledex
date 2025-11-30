# Copyright 2025, Matthias Reik <fledex@reik.org>
# Modified version of : https://github.com/SchedEx/SchedEx
#
# SPDX-License-Identifier: Apache-2.0
# SPDX-License-Identifier: MIT
defmodule Fledex.Scheduler.SchedEx.Stats.Value do
  @moduledoc """
  A statistic value.
  Caution: This is likely to be removed and replaced with telemetry
  """

  defstruct min: nil, max: nil, avg: nil, count: 0, histogram: List.duplicate(0, 20)

  @type t :: %__MODULE__{
          min: integer,
          max: integer,
          avg: float,
          count: integer,
          histogram: list(integer)
        }

  @num_periods 50
  @weight_factor 2 / (@num_periods + 1)
  @bucket_size 100

  @spec update(t(), integer) :: t()
  def update(
        %__MODULE__{min: min, max: max, avg: avg, count: count, histogram: histogram},
        sample
      ) do
    index =
      trunc(sample / @bucket_size)
      |> max(0)
      |> min(length(histogram) - 1)

    %__MODULE__{
      min: min(min, sample),
      max: (max && max(max, sample)) || sample,
      avg: (avg && (sample - avg) * @weight_factor + avg) || sample,
      count: count + 1,
      histogram: List.update_at(histogram, index, &(&1 + 1))
    }
  end
end
