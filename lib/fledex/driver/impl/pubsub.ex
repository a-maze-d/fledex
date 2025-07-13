# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.PubSub do
  @moduledoc """
  Vert experimental. Might not work
  """
  @behaviour Fledex.Driver.Interface

  alias Fledex.Color.Types
  alias Fledex.Utils.PubSub

  @impl true
  @spec configure(keyword) :: keyword
  def configure(config \\ []) do
    [
      data_name: Keyword.get(config, :data_name, :pixel_data)
    ]
  end

  @impl true
  @spec init(keyword, map) :: keyword
  def init(config, _global_config) do
    configure(config)
  end

  @impl true
  @spec reinit(keyword, keyword, map) :: keyword
  def reinit(old_config, new_config, _global_config) do
    Keyword.merge(old_config, new_config)
  end

  @impl true
  @spec transfer(list(Types.colorint()), pos_integer, keyword) :: {keyword, any}
  def transfer(leds, counter, config) do
    PubSub.direct_broadcast!(
      Keyword.get(config, :node, Node.self()),
      :fledex,
      Keyword.get(config, :topic, "trigger"),
      {:trigger, %{Keyword.fetch!(config, :data_name) => {leds, counter}}}
    )

    {config, :ok}
  end

  @impl true
  @spec terminate(reason, keyword) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _config) do
    :ok
  end
end
