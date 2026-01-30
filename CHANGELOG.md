<!--
Copyright 2025-2026, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Changelog for Fledex v0.8-dev
## Features
* First attempt to get Fledex working on AtomVM. `mix atomvm.check` does not give us any errors anymore

## Other changes
### Cleanup
* `Animation.Manager.split_config` now uses the `Enum.group_by`
* Turned all `Macro.escapes` into `unquote`. This dramatically simplified the `Fledex.Color.Names.ModuleGenerator` code. 
* Replacing `trunc(a/b)` with `div(a, b)` where ever possible

### Build
* Upgraded dependencies to latest version
* Ensured that everything works also with Elixir 1.20 (Note: Credo has a bug resulting in some warnings)

# Previous versions
The Changelog of previous versions can be found [here](https://github.com/a-maze-d/fledex/releases) 