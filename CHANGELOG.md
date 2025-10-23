# Changelog for Fledex v0.7-dev
## Flexible colors (#71)
This is a major change in how we load the color name modules. Instead of importing them into Fledex.Color.Names module, we now load the specific modules making sure that only those functions are loaded that are not conflicting.

This allows to
```elixir
use Fledex, colors: [:wiki, :ral, MyOwnColorDefinitions]
```

`Fledex.Color.Names` is now **not** generated anymore, but we use the new `Fledex.Config` to access the configured colors. It generate the `Fledex.Config.Data` that is internal to it. When `use FLedex.Config` you have the option to decide on whether you want to import
the configured colors or not. 

Since `Fledex.Color.Names` does not expose the colors directly anymore, the documentation got broken. Therefore a new mix task `mix docs.fledex.colors` generates a markdown page with all the colors of all the known color modules and got integrated into the `mix docs` process so it will be automatically generated for the documentation. This now also includes the `Fledex.Color.Names.RAL` colors.

All color name modules are now following the same behaviour `Fledex.Color.Names.Interface`

> #### Warning: {:.warning}
> This breaks a couple of things, namely the `Fledex.Color.Names` module.
> `use Fledex` several times might redefine the colors that are getting imported and should be avoided.
> Therefore components should also `import Fledex` if they want to use the macros, instead of `use Fledex` (This does mean that you would need to be explicit on all the other module names (`Leds`, color names, ...), but that's rather a good thing.

### Related changes
* With the new color handling and the new mix task we don't have a need for the custom `ex_doc` version anymore.
* Changed the `color_name_t` to allow any atom as type
* Adapted the `Fledex.Color` protocol implementation for atoms.
* Renamed `Fledex.Color.Names.Dsl` to `Fledex.Color.Names.ModuleGenerator` to better reflect it's purpose. 
* The `Fledex.Color.Names.ModuleGenerator` can now be configured to only create a set of functions instead of exposing all fields. Other color properties (and we can now have an arbitrary number, since the type `color_struct_t` has been extended) can still be retrieved through `info/1` or `info/2` or by using the `:all` parameter (WIP, we are not fully making use of this capability yet)
* updated the max xref, since we have less compile connected files
* updated the documentation and livebooks
* integrating the color guards into the color names module

## Cleanup and improved API docs (#64)
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


## Other changes
### Bugs
* Fixed a documentation bug. The hue value in HSV is a byte representing 360 degrees.

### Cleanup
* Renamed some modules to make their purpose more clear
* Renamed some functions in `Fledex.Color.Names.LoadUtils` to make their purpose more clear
* Changed the `> **Notes**` (and similar) to `> #### Note {: .info}` to be consistent and in accordance with the recommendation in the `ex_unit` documentation even though it does "break" things on `github`.
* Adding a module for HSV and HSL. `Fledex.Color.HSV` and `Fledex.Color.HSL` are now used instead of a triples. The goal is that triples are reserved for RGBs)
* Cleaning up and restructuring the conversion modules

### Depedendencies
* upgrading all dependencies to latest version

### Build
* fixing coveralls compilation issue by only running coverage on the latest supported build. Also formatting check only happens on the latest elixir version
* Adding expert to the .gitignore exclusion list


# Previous versions
The Changelog of previous versions can be found [here](https://github.com/a-maze-d/fledex/releases) 