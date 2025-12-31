<!--
Copyright 2025, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Changelog for Fledex v0.7-dev
## Flexible colors (#71, #78 and others)
This is a major change in how we load the color name modules. Instead of importing them into Fledex.Color.Names module, we now load the specific modules making sure that only those functions are loaded that are not conflicting.

This allows to
```elixir
use Fledex, colors: [:wiki, :ral, MyOwnColorDefinitions]
```

`Fledex.Color.Names` is now **not** generated anymore, but we use the new `Fledex.Config` to access the configured colors. It generate the `Fledex.Config.Data` that is internal to it. When `use FLedex.Config` you have the option to decide on whether you want to import
the configured colors or not. 

> #### Note {: .info}
> When you `use Fledex` the colors will be imported by default (but you can specify `imports: false` as option), When you `use Fledex.Config` the colors will **not** be imported by default, but you can specify `imports: true` as option.

Since `Fledex.Color.Names` does not expose the colors directly anymore, the documentation got broken. Therefore a new mix task `mix docs.fledex.colors` generates a markdown page with all the colors of all the known color modules and got integrated into the `mix docs` process so it will be automatically generated for the documentation. This now also includes the `Fledex.Color.Names.RAL` colors.

All color name modules are now following the same behaviour `Fledex.Color.Names.Interface`

> #### Warning: {:.warning}
> This breaks a couple of things, namely the `Fledex.Color.Names` module.
> `use Fledex` several times might redefine the colors that are getting imported and should be avoided.
> Therefore components should also `import Fledex` if they want to use the macros, instead of `use Fledex` (This does mean that you would need to be explicit on all the other module names (`Leds`, color names, ...), but that's rather a good thing.

### Related changes
As part of this refactoring a lot of smaller refactorings happened at the same time within the color related modules:

* With the new color handling and the new mix task we don't have a need for the custom `ex_doc` version anymore.
* Changed the `color_name_t` to allow any atom as type and most fields are optional
* Removed the most color functions from the color modules. We now only expose `:hex`, `:name`, and `:module`. The rest of the information is still present but can not be called directly. thus, you can't do `color_name(:rgb)` anymore. You can still do `info(:color_name, :rgb)` to retrieve the information.
* Adapted the `Fledex.Color` protocol implementation for atoms.
* The `Fledex.Color` protocol now only exposes a single function `to_colorint/1`. `to_rgb/1` has been removed.
* Renamed `Fledex.Color.Names.Dsl` to `Fledex.Color.Names.ModuleGenerator` to better reflect it's purpose.
* The type `color_struct_t` has been extended to allow an arbitrary number of fields and most fields are optional (except the `:hex` and `:name` values). 
* The `Fledex.Color.Names.ModuleGenerator` can now be configured to only create a set of functions (with the `fields` option) instead of exposing all fields directly. Other color properties can still be retrieved through `color_name(what)`, but it will be an indirection to `info(:color_name, what)`. Thus, you could use `info/1` or `info/2` also directly.
* Removed the properties from the color name modules that are not "natural" (now that we can do it)
* The `Fledex.Color.Names.ModuleGenerator` has been cleaned up and got added documentation
* updated the documentation and livebooks
* integrating the color guards into the color names module
* Renamed some functions in `Fledex.Color.Names.LoadUtils` to make their purpose more clear
* Adding a module for HSV, HSL, RGB. `Fledex.Color.HSV` and `Fledex.Color.HSL` are now used instead of a triples. The goal is that triples are reserved for RGBs). For consistency also introduced a `Fledex.Color.RGB`.
* Removed `Fledex.Color.to_rgb/1`. use `Fledex.Color.RGB.to_tuple(color)` instead 
* Cleaning up and restructuring the conversion modules

## Cleanup and improved API docs (#64, #83 and others)
BIG documentation improvement and cleanups including (also through other commits): 

* Added and improved the API documenation (`@specs`, `@moduledoc`, and `@doc`s)
* Restructured the API documentation to make the more useful information easier accessible
* Fixed the copyright headers
* Fixed the licenses so we are now FSF compliant. This required to replaced the cone_response picture with a version under a different license.
* Fixed also the License file issue to satisfy the scorecard tool. The overall license is now explicitly mentioned instead of being a link.
* Improved the README.md
* Updated the CREDITS.md file
* Minor improvements to the livebooks for the school (German). This is still WIP
* Added information about color correction to the 3b livebook
* Added API documentation for the conversion functions
* Updated the cheatsheet with coordinator information
* worked on the coordinator livebook (WIP)
* Documented the effect options
* Documented the driver options
* Moved the extra documentation from `docs` to `pages` (to make it less confusing with the generated api documentation by `ex_doc` that will end up in `doc`)

## Improved Supervision tree (#84, #110)
The supervision tree has been improved. 
* The `AnimationSystem` got some more functions (`start_led_strip/4`, `led_strip_exists?/1`, `get_led_strips/0`, `reconfigure_led_strip/3`, `stop_led_strip/1`) and the `LedStripSupervisor` got them as well (`start_worker/5`, `worker_exists?/3`, `get_workers/2`, `reconfigure_worker/4`, `stop_worker/3`)
* Some utility functions got created and moved around to support the above functions
* Replaced Quantum as a job scheduler with a heavily modified version of [SchedEx](https://github.com/SchedEx/SchedEx) (pulled in as a dependency. The fork can be found as [Fledex_Scheduler](https://github.com/a-maze-d/fledex_scheduler))
* Reworked the Supervision Tree. The jobs are now properly attached to the LedStrip. Also changed how the process naming is done so it's limited to the supervisors and the manager. Nobody else is aware of process names and the registry.

## Other changes
### Bugs
* Fixed a documentation bug. The hue value in HSV is a byte representing 360 degrees.
* Fixed a bug in the `Fledex.Supervisor.AnimationSystem` that prevented options to be passed correctly to the Manager. This only became apparent with 2 or more options.
* Fixed a bug in `LoadUtils.a2b/1` The value wasn't truncated to an integer
* Fixed a bug that the `Fledex.Color` protocol for `Fledex.Color.RGB didn't work in the livebook. Repositioning it solved the issue. Not sure why.

### Cleanup
* Renamed some modules to make their purpose more clear
* Changed the `> **Notes**` (and similar) to `> #### Note {: .info}` to be consistent and in accordance with the recommendation in the `ex_unit` documentation even though it does "break" things on `github`.
* Cleanued up the `Supervisor.Utils` (combined functions)
* Cleaned up the `Animation.Manager` (combined functions)
* Changed `LedStrip.reinit` to `change_config` (including the drivers). Changed the `LedStrip.change_config` to `change_global_config` because it only changes the global settings and not the drivers.
* Renamed the Job pattern to schedule (since it now also allows intervals)
* Aligned the various function names that changed the config to `change_config` (instead of `update_`, `change_`, `config`).
* Renamed `WikiUtils` to `Wiki.Converter` and removed the `filename` function which is not necessary anymore

### Depedendencies
* upgrading all dependencies to latest version
* Added `tzdata` as an optional dependency

### Build
* Adding expert to the .gitignore exclusion list
* updated the max xref, since we have less compile connected files
* Made `credo` more strict. enabled all checks that I consider as reasonable and fixed the resulting issues.
* Adding support for Elixir 1.19. The latest Elixir version also helped to also reduce the max xref (9 --> 7)
* Made the latest version to run extra tests like formatting, xref, coverage instead of doing it on all versions (since the different versions have different behaviors)
* added `ex_check`, `doctor`, `mix_audit`, `sobelow` and configured `ex_check` to run all tests.
* changed excoveralls to create html and json output so that we can use the same `mix check` and to then upload the coverage result.
* Using `ex_check` in the CI pipeline (github action)

### Security
* Fixed a directory traversal issue (even though I don't think it could be exploited since it's at compile time, but better safe than sorry!)

# Previous versions
The Changelog of previous versions can be found [here](https://github.com/a-maze-d/fledex/releases) 