defmodule Fledex.Test.CircuitsSim.Device.WS2801 do
  alias CircuitsSim.SPI.SPIServer

  defstruct nothing: "abc"
  # @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(args) do
    device = new(args)
    SPIServer.child_spec_helper(device, args)
  end

  # @spec new(keyword()) :: t()
  def new(args) do
    struct(__MODULE__, args)
  end

  defimpl CircuitsSim.SPI.SPIDevice do
    @impl true
    def transfer(state, data) do
      # The device is write only, so just return zeros.
      # result = :binary.copy(<<0>>, byte_size(data))
      result = data
      {result, state}
    end

    @impl true
    def render(_state) do
      [
        "leds: "
      ]
    end

    @impl true
    def handle_message(state, _message) do
      {:unimplemented, state}
    end
  end
end
