<!--
Copyright 2025-2026, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Changelog for Fledex v0.8-dev
## Features
* First attempt to get Fledex working on AtomVM. `mix atomvm.check` does not give us any errors anymore
* Adding support for ws2812 (via SPI port) led strips (restructued the SPI driver code). This should also support related drivers like ws2805, ws2811, ws2813, ws2814, and ws2815.
* Adding documentation on how to wire and configure the driver in `pages/hardware.md`

> #### Note {:.info}
> Only the ws2812 led strip has been tested on real hardware. the other strips have been implemented according to the specs only.

* Added support for also RGBW led strips (like the ws2813), by extending the `colorint` type to also carry the white information as `0xwwrrggbb` and `0xw2w2rrggbb` (for two white leds) and added also an `Fledex.Color.RGBW` module

> #### Warning {: .warning}
> This release breaks backward compatibility not only on a lower level, but also the DSL.
>
> The `Spi` driver has been renamed to `Spi.Ws2801`, because a second driver has been added
> for the SPI bus: `Spi.Ws2812` 

* Adding support for `:telemetry`. The first `span` as been defined: 
  * `[Fledex.LedStrip, :transfer_data]`: It measures how long it takes to transfer the data to the led strip.

* Improvements on the coordinator. 
  * Define the events more strictly, but allow to provide additional information
  * Rename the PubSub function `broadcast_state/2` to `publish_effect_event/2`
  * Rename the PubSub function `broadcast_trigger/1` to `publish_trigger/1` to be consistent in naming with the `publish_effect_event/2`
  * Moved the `effect_event_t/0` and `effect_info_event_t/0` to `Fledex.Utils.PubSub`

> #### Warning {: .warning}
> This is a BC breaking change, but it should have very minimal impact and a search and 
> replace will fix most parts. The more strict state definition has a bigger impact, but 
> is unlikely to be widely used. Should you be impacted, the best way to fix it is in 
> the following way.
> 
> Let's assume you are sending an event in the following way:
> ```elixir
> PubSub.broadcast_state(:my_special_event, %{strip_name: :john, animation: :blue})
> ```
> Then you would change it to:
> ```elixir
> PubSub.publish_effect_event({:change, :my_special_event}, %{strip_name: :john, animation: :blue})
> ```
>
> You also need to make the appropriate changes in your `Fledex.Animation.Coordinator to now
> match on the new structure.

## Other changes
### Cleanup
* `Animation.Manager.split_config` now uses the `Enum.group_by`
* Turned all `Macro.escapes` into `unquote`. This dramatically simplified the `Fledex.Color.Names.ModuleGenerator` code. 
* Replacing `trunc(a/b)` with `div(a, b)` where ever possible
* Changed the `0..255` range in typespecs to a `byte` (which corresponds to that range)
* changing the default log level to `:warning` (to not see so much output on the new livebook)

### Build
* Upgraded dependencies to latest version
* Ensured that everything works also with Elixir 1.20 (Note: Credo has a bug resulting in some warnings)
* Adding `:igniter` and `:usage_rules` as dependencies

# Previous versions
The Changelog of previous versions can be found [here](https://github.com/a-maze-d/fledex/releases) 
