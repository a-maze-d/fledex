import Config

config :circuits_sim,
  config: [
    {Fledex.Test.CircuitsSim.Device.WS2801, bus_name: "spidev0.0", render: :leds}
  ]

config :circuits_spi,
  default_backend: CircuitsSim.SPI.Backend
