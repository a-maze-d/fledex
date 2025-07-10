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
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/a-maze-d/fledex/badge)](https://scorecard.dev/viewer/?uri=github.com/a-maze-d/fledex)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/10474/badge)](https://www.bestpractices.dev/projects/10474)

<img alt="Fledex" src="assets/fledex_logo.svg" width=100/>

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

## Usage
The smoothest way is to use the Fledex DSL which defines some functions and macros. To enable them you need to `use Fledex`. This will (by default) start the animation manager (`Fledex.Animation.Manager`) through which all led definitions are routed. But don't worry, you won't really see it.

**Note:** by enabling the DSL through the `use Fledex` call, the most important modules 
are imported: `Fledex.Leds`, `Fledex.LedStrip`, `Fledex.Utils.PubSub`, `Fledex.Color.Names`, or aliased (the different drivers all part of the `FledexDriver.Impl` namespace). We will see a bit later what functionality those modules provide. 
**Note:** this could lead to the issue that you run into conflict with other libraries (like `Kino`). In that case just use the full module qualifier and prefix it with `Elixir.`

As a next step you define an LED strip through the `led_strip` macro. While defining the led strip you need to decide on how you want to talk to your strip; you need an appropriate driver.  There are several ways on how you can address your LED strip. The most common ways are through an SPI bus (`Fledex.Driver.Impl.Spi`) or through Kino (`Fledex.Driver.Impl.Kino`) as a simulated LED strip in [Livebook](https://livebook.dev/). It is possible to adjust the settings of the drivers, or even define several drivers at the same time.

This will look like the following:
```elixir
led_strip Spi do
  # ... here comes the definition of your leds ...
end
```

Once we have defined our led strip we can start to define sequences of leds. This can be achieved in 4 different ways:

* **static:** a static set of leds that do not change over time
* **animation:** an animated, i.e. changing set of leds
* **component** can encapsulate (and make the usage) of already predefined static and animated set of leds easier.

All of them define a function that defines a sequence of leds (`Fledex.Leds`). which might (or might not) change over time to give the desired effects.

Combined this might look like the following (a bit of an artificial example to demonstrate all 3 types at the same time):
```elixir
alias Fledex.Component.Dot

led_strip :nested_components, Kino do
  animation :second,
    send_config: fn _triggers ->
      %{hour: _hour, minute: _minute, second: second} = Time.utc_now()
      %{offset: second, rotate_left: false}
    end do
    _triggers ->
      leds(60) |> light(:red)
  end

  component(:minute, Dot, color: :red, count: 60, trigger_name: :minute)
  component(:hour, Dot, color: :blue, count: 24, trigger_name: :hour)

  static :helper do
    leds(5) |> light(:davy_s_grey, offset: 5) |> repeat(12)
  end
end
```

You mainly use the functionality from `Fledex.Leds` which has plenty of functions. It allows to set individual leds, provides the possibility to nest led sequences, to repeat and to define leds through some functions, like gradients and rainbow distributions.
`Fledex.Color.Names` provides a very rich set of predefined [color names](https://www.ditig.com/256-colors-cheat-sheet), but you can define it also by specifying a hex value. 
Here an example of an led squence of 10 leds with the first 3 being `red`, `green`, and  `0x0000ff` (blue). The rest will be black (off).
```elixir
  leds(10) |> red() |> light(:green) |> light(0x0000ff)
```

There is also a rich set of support functionality to make the definition of LED strips (and especially animations) easier, like:

* `Fledex.Effect.*` to define some effects (like Dimming, Wanish, ...) on a sequence of leds
* `Fledex.job` to define repetitive tasks, like fetching some weather information

Take a look at the [Livebook examples](README.md#livebook) on how to use the DSL. Note: the livebooks do present also the internals how the library works. As a first step you can skip those.

## Livebook
As mentioned above, the library works well in conjunction with [Livebook](https://livebook.dev/) so you probably want to take your first steps with it. You can find some [livebooks](livebooks/README.md) files that show you how to use the library in a notebook (with and without hardware). You should be able to do most of your development on a computer (emulating the LED strip with a `Fledex.Driver.Impl.Kino` driver) before adjusting it to the real hardware (with the `Fledex.Driver.Impl.Spi` driver). On real hardware you can even run it with serveral drivers at the same time.

# Nerves-Livebook
To run Fledex in a [Nerves-Livebook](https://github.com/nerves-livebook/nerves_livebook) is not quite as easy, because you can't dynamically add libraries. You can only use those libraries that have been added while building the nerves ROM.

Thus, you will have to clone the repository and add in the `mix.exs` file `fledex` as a new dependency.

```elixir
defp deps do
  [
    ...
    {:fledex, "~>0.5}
  ]
```

Then you fetch the dependencies and recompile the project (adjust the `MIX_TARGET` to your hardware, here a Raspberry Pi Zero W is used):
```shell
export MIX_TARGET=rpi0
mix deps.get
mix compile
```

Once done you follow the [standard installation instructions](https://github.com/nerves-livebook/nerves_livebook?tab=readme-ov-file#burning-the-firmware-for-devices-that-boot-from-microsd)

## Further Docs
you can find some further documentation in the `docs` folder about:

* An Overview over the [Architecture](docs/architecture.md)
* How to setup and connect real [Hardware](docs/hardware.md)
* You might find in the folder also some temporary documenation with some thoughts, but I delete them again, once they have fulfilled their purpose, except for: 
* A bit of history with the [Project Plan](docs/project_plan.md) as created with my son, since it's a nostalgic document (partially in German)

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
