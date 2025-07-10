# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
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
  @spec configure(keyword) :: keyword
  def configure(_config) do
    [
      # not storing anything
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
  def transfer(_leds, _counter, config) do
    {config, :ok}
  end

  @impl true
  @spec terminate(reason, keyword) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _config) do
    # nothing needs to be done here
    :ok
  end
end
