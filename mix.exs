defmodule Fledex.MixProject do
  use Mix.Project

  def project do
    [
      app: :fledex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "fledex",
      source_url: "https://github.com/a-maze-d/fledex"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

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
      {:circuits_spi, "~> 1.4"},
      {:telemetry, "~> 1.2"},
      {:kino, "~>0.8"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
