# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.PubSubTest do
  use ExUnit.Case

  alias Fledex.Driver.Impl.PubSub, as: Driver
  alias Fledex.Supervisor.Utils
  alias Fledex.Utils.PubSub

  setup do
    start_supervised({Registry, name: Utils.worker_registry()})
    start_supervised({Phoenix.PubSub, [name: Utils.pubsub_name(), adapter_name: :pg2]})

    PubSub.subscribe(Utils.pubsub_name(), "trigger")
  end

  describe "test driver basic tests" do
    test "default init" do
      config = Driver.init([data_name: :pixel_data], [])
      assert Keyword.fetch!(config, :data_name) == :pixel_data
    end

    test "reinit" do
      config = [data_name: :pixel_data]
      assert config == Driver.reinit(config, [], [])
    end

    test "transfer" do
      driver = Driver.init([data_name: :pixel_data], [])

      assert {driver, :ok} ==
               Driver.transfer(
                 [0xFF0000, 0x00FF00, 0x0000FF],
                 74,
                 driver
               )

      assert_receive {:trigger, %{pixel_data: {[0xFF0000, 0x00FF00, 0x0000FF], 74}}}
    end

    test "terminate" do
      driver = Driver.init([data_name: :pixel_data], [])
      assert :ok == Driver.terminate(:normal, driver)
    end
  end
end
