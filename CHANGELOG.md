<!--
Copyright 2025-2026, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Changelog for Fledex v0.9.0-dev

## BC (backward compatible) breaking changes
* The offset changes are breaking backward compatibility, but the adjustments should be quite easy and staight forward. Zero and negative offsets are now allowed. This is not per se a BC breaking change, but worthwhile to call out

## Features
*  Adding support to the Spi.Ws2812 driver for Adafruit Neopixel Pebbles (SK6812) with `:bgr` color order. Also adding support for custom color orders
* led offsets are now allowed to be zero and even negative. This makes the creations of animations easier. It also brings consistency across various parts

## Other changes
### Documentation
* Documentation improvements for the Spi.Ws2812 driver and hardware setup
* Adding Nerves compatibility badge to the README
 
### Cleanup
* Adding `handle_info({:EXIT, _, _}, state)` for workers
* adding supervisor type to the supervisor child specs
* Added some missing type specs


### Bugs
* Fixing an SPI Utils bug (not merging the configs properly together)


### Tests

### Build
* Adding argus_beam (adding also to `mix check`)
* Updating dependencies

# Previous versions
The Changelog of previous versions can be found [here](https://github.com/a-maze-d/fledex/releases) 
