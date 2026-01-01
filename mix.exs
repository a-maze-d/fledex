# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.MixProject do
  use Mix.Project

  @version "0.7.0"
  @source_url "https://github.com/a-maze-d/fledex"
  def project do
    [
      app: :fledex,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "fledex",
      source_url: @source_url,
      dialyzer: [
        # plt_add_deps: :apps_direct,
        check_plt: true,
        incremental: true,
        plt_add_apps: [:mix],
        flags: [
          # :missing_return,
          # :extra_return,
          # :unmatched_returns,
          :error_handling
          # :underspecs
        ]
      ],
      test_coverage: [
        tool: ExCoveralls,
        ignore_modules: [
          Fledex.Test.CircuitsSim.Device.WS2801,
          Fledex.Component.Thermometer
        ]
      ],
      docs: docs(),
      aliases: aliases()
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.github": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test,
        "coveralls.multiple": :test,
        # credo: :test,
        check: :test,
        dialyzer: :dev
        # "deps.audit": :test,
        # docs: :dev,
        # "docs.fledex.colors": :dev,
        # doctor: :test
        # sobelow: :dev
      ]
    ]
  end

  # specified per env which files to compile. For tests we add the support folder
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # specified per env which compilation options to use
  # the color creation can take quite a while, therefore increasing the threshold
  defp elixirc_options(_), do: [long_compilation_threshold: 60_000]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications:
        [:logger, :wx, :observer, :runtime_tools] ++ extra_applications(Mix.env()),
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
      {:libcluster, "~> 3.3"},
      {:tzdata, "~> 1.1", optional: true},
      {:fledex_scheduler, "~>0.1"},

      # observability
      {:telemetry, "~> 1.2"},

      # testing
      {:circuits_sim, "~> 0.1.0", only: [:dev, :test]},

      # documentation
      # ">= 0.0.0", only: :dev, runtime: false},
      {:ex_doc, "~>0.38", only: :dev, runtime: false},

      # documentation coverage is a great idea, but there are several major issues:
      # * The file inch_ex/lib/inch_ex/docs.ex#L74 needs to look like the following to not
      #   throw an error: `"location" => "#{inspect source}:#{inspect anno}"`
      # * The library does not understand the `@doc delegate_to` functionality
      # * The library sees no documentation on a macro that has A LOT of docs
      # Therefore disabling it (again)
      # {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test]},

      # code quality
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:credo_binary_patterns, "~> 0.2.3", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_check, "~> 0.16.0", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.22.0", only: [:dev, :test], runtime: false},
      # required by excoveralls
      {:castore, "~> 1.0", only: :test},
      # check licenses by calling `mix licenses` disabled by default (because the
      # library is not well maintained and throws some warnings), but when we want
      # to check licenses we can enable it easily.
      # {:licensir, "~>0.7.0", only: :test}
      # we are not a phoenix app, but can still reveal some interesting stuff.
      # leaving it out by default though
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false, warn_if_outdated: true}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @source_url,
      assets: %{
        "assets" => "assets",
        "pages/assets" => "assets",
        "livebooks/school/assets" => "assets"
      },
      main: "readme-1",
      logo: "assets/fledex_logo.svg",
      favicon: "assets/favicon.png",
      authors: ["a-maze-d"],
      extras: [
        "README.md",
        "LICENSE.md",
        "SECURITY.md",
        "CLA.md",
        "CONTRIBUTING.md",
        "CONTRIBUTORS.md",
        "CODE_OF_CONDUCT.md",
        "pages/architecture.md",
        "pages/hardware.md",
        "pages/project_plan.md",
        "pages/cheatsheet.cheatmd",
        "pages/colors.md",
        "livebooks/README.md",
        "livebooks/1_first_steps_with_an_led_strip.livemd",
        "livebooks/2_fledex_first_steps.livemd",
        "livebooks/2b_fledex_how_to_define_leds.livemd",
        "livebooks/3_fledex_animations.livemd",
        "livebooks/3b_fledex_everything_about_colors.livemd",
        "livebooks/4_fledex_clock_example.livemd",
        "livebooks/5_fledex_weather_example.livemd",
        "livebooks/6_fledex_dsl.livemd",
        "livebooks/7_fledex_effects.livemd",
        "livebooks/8_fledex_component.livemd",
        "livebooks/9_fledex_jobs.livemd",
        "livebooks/school/licht_und_farben.livemd",
        "livebooks/school/hardware_erklaerung.livemd"
      ],
      groups_for_extras: [
        LiveBooks: ~r/livebooks\/[^\/]*\.(?:live)?md/,
        "LiveBooks (German)": ~r/livebooks\/school/,
        "Other Project Info": [
          "SECURITY.md",
          "CLA.md",
          "CONTRIBUTING.md",
          "CODE_OF_CONDUCT.md",
          "CONTRIBUTORS.md",
          "LICENSE.md"
        ]
      ],
      groups_for_modules: [
        "Core:": [
          Fledex,
          Fledex.Color,
          Fledex.Config,
          Fledex.LedStrip,
          Fledex.Leds
        ],
        "Core: Color Names": [
          Fledex.Color.Names.Interface,
          Fledex.Color.Names,
          Fledex.Color.Names.CSS,
          Fledex.Color.Names.RAL,
          Fledex.Color.Names.SVG,
          Fledex.Color.Names.Wiki
        ],
        "Core: Components": ~r/Fledex.Component/,
        "Core: Drivers": ~r/Fledex.Driver.Impl/,
        "Core: Effects": ~r/Fledex.Effect/,
        "Details: Animation": ~r/Fledex.Animation/,
        "Details: Color": ~r/Fledex.Color/,
        "Details: Driver": ~r/Fledex.Driver/,
        "Details: Scheduler": ~r/Fledex.Scheduler/,
        "Details: Supervisor": [~r/Fledex.Supervisor/, Fledex.Application],
        "Details: Utils": ~r/Fledex.Utils/
      ],
      groups_for_docs: [
        Guards: & &1[:guard],
        "Color Names": & &1[:color_name]
      ],
      copy_doc_decorator: fn doc, {_m, _f, _a} -> doc end
    ]
  end

  defp aliases do
    [
      docs: ["docs.fledex.colors", "docs"],
      # test: ["coveralls.html"],
      reuse: [&run_reuse/1]
    ]
  end

  defp run_reuse(_) do
    {response, exit_status} = System.cmd("pipx", ["run", "reuse", "lint"])
    IO.puts(response)

    case exit_status do
      0 -> :ok
      error -> Mix.raise("Reuse failed with error code: #{error}")
    end
  end
end
