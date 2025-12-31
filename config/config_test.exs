# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

import Config

config :logger, level: :info
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :circuits_sim,
  config: [
    {Fledex.Test.CircuitsSim.Device.WS2801, bus_name: "spidev0.0", render: :leds}
  ]

config :circuits_spi,
  default_backend: CircuitsSim.SPI.Backend
