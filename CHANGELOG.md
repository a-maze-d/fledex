<!--
Copyright 2025-2026, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Changelog for Fledex v0.8-dev
## Features
* First attempt to get Fledex working on AtomVM. `mix atomvm.check` does not give us any errors anymore

> #### Warning {: .warning}
> This release breaks backward compatibility not only on a lower level, but also the DSL.
>
> The `Spi` driver has been renamed to `Spi.Ws2801`, because a second driver has been added
> for the SPI bus: `Spi.Ws2812` 
## Feature
* First attempt to get Fledex working on AtomVM. `mix atomvm.check` does not give us any errors anymore
* Adding support for ws2812 (via SPI port) led strips (restructued the SPI driver code). This should also support related drivers like ws2813, ws2814, and ws2815
* Added support for also RGBW led strips (like the ws2813), by extending the `colorint` type to also carry the white information as `0xwwrrggbb` and added also an `Fledex.Color.RGBW` module

## Other changes
### Cleanup
* `Animation.Manager.split_config` now uses the `Enum.group_by`
* Turned all `Macro.escapes` into `unquote`. This dramatically simplified the `Fledex.Color.Names.ModuleGenerator` code. 
* Replacing `trunc(a/b)` with `div(a, b)` where ever possible
* Changed the `0..255` range in typespecs to a `byte` (which corresponds to that range)

### Build
* Upgraded dependencies to latest version
* Ensured that everything works also with Elixir 1.20 (Note: Credo has a bug resulting in some warnings)

# Previous versions
The Changelog of previous versions can be found [here](https://github.com/a-maze-d/fledex/releases) 