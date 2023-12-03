defmodule Fledex.Driver.Impl.PubSubDriverTest do
  use ExUnit.Case

  alias Fledex.Driver.Impl.PubSubDriver
  alias Fledex.Utils.PubSub

  setup do
    :ok = PubSub.subscribe(:fledex, "driver")
    on_exit(:unsubscribe, fn -> PubSub.unsubscribe(:fledex, "driver") end)
  end

  describe "test driver basic tests" do
    test "default init" do
      config = PubSubDriver.init(%{})
      assert config.data_name == :pixel_data
    end
    test "reinit" do
      init_config = %{data_name: :pixel_data}
      assert init_config == PubSubDriver.reinit(init_config)
    end
    test "transfer" do
      driver = PubSubDriver.init(%{})
      assert {driver, :ok} == PubSubDriver.transfer(
        [0xff0000, 0x00ff00, 0x0000ff],
        74,
        driver
      )
      assert_receive {:driver, %{pixel_data: [0xff0000, 0x00ff00, 0x0000ff]}}
    end
    test "terminate" do
      driver = PubSubDriver.init(%{})
      assert :ok == PubSubDriver.terminate(:normal, driver)
    end

  end
end
