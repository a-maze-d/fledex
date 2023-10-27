defmodule Fledex.TestHelpers.LedAnimatorHelper do
  require Logger
  alias Fledex.Leds

  #just some empty shells
  def default_def_func(_triggers) do
    Leds.new(30)
  end
  def default_send_config_func(_triggers) do
    %{namespace: "test"}
  end

  # some logging versions to test the workflow
  def logging_def_func(_triggers) do
    Logger.info("creating led definition")
    Leds.new(30)
  end
  def logging_send_config_func(_triggers) do
    Logger.info("creating send config")
    %{namespace: "test#{ExUnit.configuration()[:seed]}"}
  end
end
