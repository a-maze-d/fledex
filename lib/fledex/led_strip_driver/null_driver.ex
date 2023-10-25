defmodule Fledex.LedStripDriver.NullDriver do
  @behaviour Fledex.LedStripDriver.Driver

  alias Fledex.Color.Types
  @moduledoc """
    This is a dummy implementation of the LedStripDriver that doesn't do
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
  @spec transfer(list(Types.colorint), pos_integer, map) :: map
  def transfer(_leds, _counter, config) do
    config
  end

  @impl true
  @spec terminate(reason, map) :: :ok when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, _state) do
    # nothing needs to be done here
    :ok
  end
end
