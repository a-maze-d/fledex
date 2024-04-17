# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.PubSub do
  @behaviour Fledex.Driver.Interface

  alias Fledex.Color.Types
  alias Fledex.Utils.PubSub

  @default_config %{data_name: :pixel_data}
  @spec init(map) :: map
  def init(module_init_args) do
    Map.merge(@default_config, module_init_args)
  end

  @spec reinit(map) :: map
  def reinit(module_config) do
    module_config
  end

  @spec transfer(list(Types.colorint()), pos_integer, map) :: {map, any}
  def transfer(leds, counter, config) do
    PubSub.simple_broadcast(%{config.data_name => {leds, counter}})
    {config, :ok}
  end

  @spec terminate(reason, map) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _config) do
    :ok
  end
end
