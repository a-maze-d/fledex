defmodule Fledex.MixProject do
  use Mix.Project

  def project do
    [
      app: :fledex,
      version: "0.2.0",
      elixir: "~> 1.14",
      elixirc_path: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "fledex",
      source_url: "https://github.com/a-maze-d/fledex"
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
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/a-maze-d/fledex"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_spi, "~> 2.0-pre.0"},
      {:telemetry, "~> 1.2"},
      {:kino, "~>0.11"},
      {:phoenix_pubsub, "~>2.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:circuits_sim, git: "https://github.com/elixir-circuits/circuits_sim/", only: [:dev, :test]}
    ]
  end
end
