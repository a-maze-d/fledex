# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.PubSubTest do
  use ExUnit.Case

  alias Fledex.Driver.Impl.PubSub, as: Driver
  alias Fledex.Utils.PubSub

  setup do
    :ok = PubSub.subscribe(:fledex, "driver")
    on_exit(:unsubscribe, fn -> PubSub.unsubscribe(:fledex, "driver") end)
  end

  describe "test driver basic tests" do
    test "default init" do
      config = Driver.init(%{})
      assert config.data_name == :pixel_data
    end

    test "reinit" do
      init_config = %{data_name: :pixel_data}
      assert init_config == Driver.reinit(init_config)
    end

    test "transfer" do
      driver = Driver.init(%{})

      assert {driver, :ok} ==
               Driver.transfer(
                 [0xFF0000, 0x00FF00, 0x0000FF],
                 74,
                 driver
               )

      assert_receive {:driver, %{pixel_data: [0xFF0000, 0x00FF00, 0x0000FF]}}
    end

    test "terminate" do
      driver = Driver.init(%{})
      assert :ok == Driver.terminate(:normal, driver)
    end
  end
end
