defmodule LedStripDriver do
  @callback init(init_args :: map(), state :: map()) :: map()
  @callback transfer(leds :: list(integer), state :: map()) :: map()
  @callback terminate(reason, state :: map()) :: :ok
    when reason: :normal | :shutdown | {:shutdown, term()} | term()
end
