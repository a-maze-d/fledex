<!--
Copyright 2023-2024, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Fledex
[![Hex.pm](https://img.shields.io/hexpm/l/fledex "License")](https://github.com/a-maze-d/fledex/blob/main/LICENSES/Apache-2.0.txt)
[![Hex version](https://img.shields.io/hexpm/v/fledex.svg?color=0000ff "Hex version")](https://hex.pm/packages/fledex)
[![API docs](https://img.shields.io/hexpm/v/fledex.svg?label=hexdocs&color=0000ff "API docs")](https://hexdocs.pm/fledex)
[![ElixirCI](https://github.com/a-maze-d/fledex/actions/workflows/elixir.yml/badge.svg "ElixirCI")](https://github.com/a-maze-d/fledex/actions/workflows/elixir.yml)
[![REUSE status](https://api.reuse.software/badge/github.com/a-maze-d/fledex)](https://api.reuse.software/info/github.com/a-maze-d/fledex)
[![Coverage Status](https://coveralls.io/repos/github/a-maze-d/fledex/badge.svg?branch=main)](https://coveralls.io/github/a-maze-d/fledex?branch=main)
[![Downloads](https://img.shields.io/hexpm/dt/fledex.svg)](https://hex.pm/packages/fledex)

<img alt="Fledex" src="fledex_logo.svg" width=100/>

Fledex is a small [Elixir](https://elixir-lang.org/) library It really is intended for educational purposes.
It is written for a RaspberryPi Zero W running [Nerves](https://nerves-project.org/) especially with a [Nerves-Livebook](https://hexdocs.pm/nerves/getting-started.html#nerves-livebook), but you could use it without Nerves or Livebook.

The intent of the library is to simplify the programming of a programmable LED strip (currently based on a [WS2801 chip](https://cdn-shop.adafruit.com/datasheets/WS2801.pdf)) and thereby to make it accessible even for kids.

The idea is to introduce similarly easy concepts for the programming of LEDs as [SonicPi](https://sonic-pi.net/) did for music. The library was developed in collaboration with my son and hopefully we can push it to become better over time. For my son the goal will be to connect the LEDs to some music and to animate the LEDs depending on the beat.

Quite a lot of inspiration came from the [FastLED project](http://fastled.io/) and quite a few of their functions got reimplemented in Elixir. If you look at the implementation of some of those functions you might want to look at their comments.

## Installation

The library is [available in Hex](https://hex.pm/packages/fledex), the package can be installed
by adding `:fledex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fledex, "~> 0.5"}
  ]
end
```

TODO: This whole section needs some updating, since it has become much easier now that we can `use Fledex` to load the macros

Once in you have installed the library and run your usual `mix deps.get` you can start the LedStrip Server by calling:
```elixir
{:ok, pid} = LedStrip.start_link(:strip_name)
```

The `Fledex.LedStrip` should have quite reasonable defaults to get you started (a `Fledex.Driver.Impl.Null` driver is used by default)

Your interaction with the LedDriver should mainly happen through the Leds module. To set the first 3 LEDs (of a 50 LED strip) to red, green and blue you would do the following (here the [color names](https://www.ditig.com/256-colors-cheat-sheet) are used, but you could have used the hex values `0xFF0000`, `0x00FF00`, and `0x0000FF` too):
```elixir
LedStrip.define_namespace(:default)
Leds.leds(50)
  |> Leds.light(:red)
  |> Leds.light(:green1) 
  |> Leds.light(:blue)
  |> Leds.send() # :default namespace is used as default
```
All other LEDs would be set to off

The above approach is rather cumbersome with a lot of LEDs, and would be even more difficult if you want to animate it. Thus, instead of managing the LED strip yourself, you should use the Fledex DSL.

Take a look at the [Livebook examples](README.md#livebook) on how to use the DSL

## Livebook
As mentioned above, the library works well in conjunction with Livebook so you probably want to take your first steps with it. You can find some [livebooks](livebooks/README.md) files that show you how to use the library in a notebook (with and without hardware). You should be able to do most of your development on a computer (emulating the LED strip with a `Fledex.Driver.Impl.Kino`) before adjusting it to the real hardware (with the `Fledex.Driver.Impl.Spi`). On real hardware you can even run it with serveral drivers at the same time.

# Nerves-Livebook
TODO: Add more info...

## Further Docs
you can find some further documentation in the `docs` folder about:

* An Overview over the [Architecture](docs/architecture.md)
* How to setup and connect real [Hardware](docs/hardware.md)
* You might find in the folder also some temporary documenation with some thoughts, but I delete them again, once they have fulfilled their purpose, except for: 
* A bit of history with the [Project Plan](docs/project_plan.md) as created with my son, since it's a nostalgic document

## Known Limitations
If you want to run this library in nerves-livebook, you currently have to compile your own livebook with the library included in your `mix.exs` file, since you can't add any libraries that are not already bundled.

## Contributing
Contributions of any kind are very much welcome

* raising issues, 
* raising PR (see also [this](CLA.md) doc), 
* reporting security vulnerabilities (see also [this](SECURITY.md) doc), 
* suggesting improvements to documentation incl. reporting typos, 
* raising feature requests,
* ... 

Before doing so please make sure to also read through the [CONTRIBUTING](CONTRIBUTING.md) document and ensure to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

If you need any assistance, feel free to send an email to fledex at reik.org