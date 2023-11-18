defmodule Fledex.LedStripDriver.PubsubDriver do
  @behaviour Fledex.LedStripDriver.Driver

  alias Fledex.Utils.PubSub

  @default_config %{data_name: :pixel_data}
  def init(module_init_args) do
    Map.merge(@default_config, module_init_args)
  end
  def reinit(module_config) do
    module_config
  end
  def transfer(leds, _counter, config) do
    PubSub.broadcast(:fledex, "triggers", {:triggers, %{config.data_name => leds}})
    {config, :pk}
  end
  def terminate(_reason, _config) do
    :ok
  end
end
