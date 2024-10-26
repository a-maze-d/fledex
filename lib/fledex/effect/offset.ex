# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Offset do
  @behaviour Fledex.Effect.Interface

  alias Fledex.Color.Types

  @impl true
  @spec apply(
          leds :: list(Types.colorint()),
          count :: non_neg_integer,
          config :: keyword,
          triggers :: map,
          context :: map
        ) ::
          {list(Types.colorint()), non_neg_integer, map}
  def apply(leds, 0, _config, triggers, _context), do: {leds, 0, triggers}

  def apply(leds, count, config, triggers, context) do
    case enabled?(config) do
      true ->
        do_apply(leds, count, config, triggers, context)

      false ->
        {leds, count, config}
    end
  end

  defp do_apply(leds, count, config, triggers, _context) do
    offset = config[:offset] || 1

    zeros = Enum.map(Enum.to_list(1..offset), fn _index -> 0 end)
    {zeros ++ leds, count + offset, triggers}
  end

  @impl true
  @spec enable(config :: keyword, enable :: boolean) :: keyword
  def enable(config, enable) do
    Keyword.put(config, :enabled, enable)
  end

  @impl true
  @spec enabled?(config :: keyword) :: boolean
  def enabled?(config) do
    Keyword.get(config, :enabled, true)
  end
end
