# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

import Config

config :logger, level: :info
config :fledex, Fledex.Animation.JobScheduler, debug_logging: false

config :circuits_sim,
  config: [
    {Fledex.Test.CircuitsSim.Device.WS2801, bus_name: "spidev0.0", render: :leds}
  ]

config :circuits_spi,
  default_backend: CircuitsSim.SPI.Backend
