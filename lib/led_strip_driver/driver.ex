defmodule Fledex.LedStripDriver.Driver do
  use Fledex.Color.Types

  @callback init(init_args :: map, state :: Fledex.LedDriver.t) :: Fledex.LedDriver.t
  @callback transfer(leds :: list(colorint), state :: Fledex.LedDriver.t) :: Fledex.LedDriver.t
  @callback terminate(reason, state :: Fledex.LedDriver.t) :: :ok
    when reason: :normal | :shutdown | {:shutdown, term()} | term()
end
