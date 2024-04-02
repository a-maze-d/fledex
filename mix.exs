# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/a-maze-d/fledex"
  def project do
    [
      app: :fledex,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "fledex",
      source_url: @source_url,
      # dialyzer: [
      #   flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs]
      # ],
      test_coverage: [
        tool: ExCoveralls,
        ignore_modules: [
          Fledex.Test.CircuitsSim.Device.WS2801,
          Fledex.Effect.Sequencer,
          Fledex.Component.Thermometer
        ],
      ],
      docs: docs(),
      aliases: aliases(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.github": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test,
        "coveralls.multiple": :test
      ]
    ]
  end

  # specified per env which files to compile
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger] ++ extra_applications(Mix.env),
      mod: {Fledex.Application, []}
    ]
  end

  defp extra_applications(env)
  defp extra_applications(:dev), do: [:circuits_sim]
  defp extra_applications(:test), do: [:circuits_sim]
  defp extra_applications(_), do: []

  defp description() do
    "A small library to easily control an LED strip with nerves (or nerves-livebook)"
  end
  defp package() do
    [
      name: "fledex",
      maintainers: ["Matthias Reik"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/a-maze-d/fledex"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:circuits_i2c, "~> 2.0"},
      {:circuits_spi, "~> 2.0"},
      # {:circuits_gpio, "~> 2.0"},

      {:kino, "~> 0.11"},
      {:phoenix_pubsub, "~> 2.1"},
      # {:libcluster, "~> 3.3"},
      {:quantum, "~> 3.0"},

      # observability
      {:telemetry, "~> 1.2"},

      # testing
      {:circuits_sim, "~> 0.1.0", only: [:dev, :test]},

      # documentation
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},

      # code quality
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:credo_binary_patterns, "~> 0.2.3", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:castore, "~> 1.0"}, # required by excoveralls
    ]
  end
  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @source_url,
      main: "readme-1",
      extras: [
        "README.md",
        "SECURITY.md",
        "CLA.md",
        "CONTRIBUTING.md",
        "CONTRIBUTORS.md",
        "CODE_OF_CONDUCT.md",
        "docs/architecture.md",
        "docs/hardware.md",
        "livebooks/README.md",
        "livebooks/1_first_steps_with_an_led_strip.livemd",
        "livebooks/2_fledex_first_steps.livemd",
        "livebooks/2b_fledex_how_to_define_leds.livemd",
        "livebooks/3_fledex_animations.livemd",
        "livebooks/3b_fledex_more_about_colors.livemd",
        "livebooks/4_fledex_clock_example.livemd",
        "livebooks/5_fledex_weather_example.livemd",
        "livebooks/6_fledex_dsl.livemd",
        "livebooks/7_fledex_effects.livemd",
        "livebooks/8_fledex_component.livemd"
      ],
      groups_for_extras: [
        "LiveBooks": ~r/livebooks/,
        "Other Project Info": [
          "SECURITY.md",
          "CLA.md",
          "CONTRIBUTING.md",
          "CODE_OF_CONDUCT.md",
          "CONTRIBUTORS.md",
         ]
      ],
      groups_for_modules: [
        "Core": [
          Fledex,
          Fledex.LedStrip,
          Fledex.Leds,
          Fledex.Application
        ],
        "Animation": ~r/Fledex.Animation/,
        "Driver Implementations": ~r/Fledex.Driver.Impl/,
        "Driver": ~r/Fledex.Driver/,
        "Utils": ~r/Fledex.Utils/,
        "Color": ~r/Fledex.Color/,
      ],
      groups_for_docs: [
        "Color Names": & &1[:color_name]
      ]
    ]
  end
  defp aliases do
    [
      docs: ["docs", &copy_doc_images/1],
      test: ["coveralls.html"],
      reuse: [&run_reuse/1]
    ]
  end
  defp run_reuse(_) do
    {response, _exit_status} = System.cmd("pipx", ["run", "reuse", "lint"])
    IO.puts(response)
  end
  defp copy_doc_images(_) do
    images = [
      {"docs/architecture.drawio.svg", "doc/architecture.drawio.svg"},
      {"docs/hardware.drawio.svg", "doc/hardware.drawio.svg"},
      {"docs/hardware-Page-2.drawio.svg", "doc/hardware-Page-2.drawio.svg"}
    ]
    Enum.each(images, fn {from, to} ->
      File.cp(from, to, on_conflict: fn (_source, _destination) -> true end)
    end)
  end
end
