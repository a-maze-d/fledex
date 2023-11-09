# TODO: I haven't managed to configure things correctly so that we can move this
#       module into the test/support folder :-( Things should work, but something is not quite right
#       Problem is that we can't leave it here because we want to keep the CircuitsSim library
#       for tests only. Thus this won't compile in non-test mode :-(
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
      result = :binary.copy(<<0>>, byte_size(data))
      {result, state}
    end

    @impl true
    def render(_state) do
      [
        # case state.render do
        #   :default -> TM1620.binary_clock(state.data)
        # end
      ]
    end

    @impl true
    def handle_message(state, _message) do
      {:unimplemented, state}
    end
  end
end
