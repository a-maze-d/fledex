# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.Null do
  @behaviour Fledex.Driver.Interface

  alias Fledex.Color.Types
  @moduledoc """
    This is a dummy implementation of the Driver that doesn't do
    anything (similar to a /dev/null device). This can be useful if you
    want to run some tests without getting any output or sending it to hardware.
  """
  @impl true
  @spec init(map) :: map
  def init(_init_module_args) do
    %{
      # not storing anything
    }
  end

  @impl true
  @spec reinit(map) :: map
  def reinit(module_config) do
    module_config
  end

  @impl true
  @spec transfer(list(Types.colorint), pos_integer, map) :: {map, any}
  def transfer(_leds, _counter, config) do
    {config, :ok}
  end

  @impl true
  @spec terminate(reason, map) :: :ok when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _state) do
    # nothing needs to be done here
    :ok
  end
end
