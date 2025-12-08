<!--
Copyright 2023-2025, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
Even though this library is published, there are things I still want to do before I consider this as really done. Here the outstanding tasks that I can think of.

# Tasks
- [ ] Documentation
  - [x] Add information about color correction (section 3b) (v0.7)
  - [x] Improve API documentation (v0.7)
  - [x] Update the documentation with new color name information (v0.7)
  - [x] Create a new color page, since the colors will not be available through `Fledex.Color.Names` directly (v0.7)
  - [x] Document the driver options (v0.7)
  - [x] Update the cheatsheet with coordinator info (v0.7)
  - [ ] Add a livebook with coordinator examples (v0.7)
  - [ ] Update documentation with the Supervision tree (v0.8)
  - [ ] hardware setup (analogy with a bus letting 24 passangers off the bus at every led-bus-stop). Create a comprehensive write-up (v0.8)
- [ ] Testing
  - [x] Test all the livebooks (v0.7)
  - [x] Restructure the tests, so they are not so fragile (due to `Fledex.Config`) (v0.7) <-- this does not seem to be an issue anymore.
  - [x] Test with Elixir 1.19 (v0.7)
  - [x] Increase the credo checks (enable all reasonable ones) (v0.7)
  - [ ] Add tests for the Clock component (v0.8)
  - [ ] Add tests for the Thermometer component (v0.8)
- [ ] Cleanup
  - [x] Cleanup the color conversion functions. There are a lot of unused parts, providing flexibility that is not required.
  - [x] Add more guards to functions to make them more robust (v0.7)
  - [x] All Color name modules have the same interface (through the DSL it's even enforced). Let's make this more explicit by introducting a Color.Names.Interface with the appropriate callbacks (v0.7)
  - [x] We could change the `Fledex.Color` for `Atom` to delegate to any of the color modules until we find the module that implements it. Defaulting to black if the color does not exist. Thus, we wouldn't even need any specific `color_name` guard, since any atom would be "kind of" valid. I think that would dramatically reduce the dependencies. Downside is that it wouldn't be possible to look at all the colors that are implemented at compiletime, but for that we have runtime functions and that's probably where we would need them the most. (v0;7)
  - [x] Change the import of `Fledex.Color.Names` and import the different color components individually instead. `Fledex.Color.Names` still makes sense to bind those together. The import can be done in a flexible way. This should reduce the complexity of the code, the dependencies, and increase the flexibility without loss of convenience for the user (v0.8)
  - [x] Check whether we could unload the module first before we we redefine it. The unloading could be done with [`:code.delete(module)](https://www.erlang.org/doc/apps/kernel/code.html#delete/1). This could allow us to ALLWAYS define the module and redefine an inner module. (v0.7)
  - [x] components shouldn't `use` but `import` Fledex. This way we would solve a lot of issues.
  - [x] Introduce a `Fledex.Color.RGB` and reduce the reliance on `{r, g, b}` tuples
  - [x] Remove `Fledex.Color.to_rgb/1`
  - [x] Avoid the `RGB.new(color) |> RGB.to_tuple()` constructs, by changing the various functions to take RGB structures. The RGB-tuple should only be used by clients but not internally.
  - [ ] Rename `docs` to `pages`. Some people find it confusing to have a `docs` and a `doc` (created by `ex_doc`) (v0.7)
  - [ ] Rethink whether we really want to create a `Fledex.Config.Data` module or we should store the information in a GenServer. The issue with the GenServer is that we need to start a server. But maybe that's not soo bad. (v0.9)
- [ ] Missing functionality
  - [x] Allow selecting the color modules that can be loaded instead of loading always the same list by default. (v0.7)
  - [x] We have the `Fledex.Color` protocol, but we actually don't make use of its type. This is maybe also a good opportunity to rethink on how we handle colors in general. Maybe we should define everything as `Fledex.Color` and encapsulate CSS, SVG, RAL colors in their own struct to then have the protocol implemented for them. (v0.7)
  - [x] Allow color modules to not carry more information than just a pre-defined set (v0.7)
  - [x] convert the rgb to other color spaces (in the various color name modules). Considering the previous point we might not need to do this, because it should now be optional (v0.7) <-- reduced the generated color functions, and what gets exposed
  - [x] we start things through the Supervisor, but we don't shut things down through it (v0.7)
  - [ ] Put some more effort into the coordinator to make it work well (v0.7)
  - [ ] Rework the `:job` implementation (v0.8):
    - [ ] The Job should (at least appear) to be connected to the LedStrip
    - [ ] Replace it with a different library (maybe `SchedEx`? https://hexdocs.pm/sched_ex/readme.html) (v0.8)
      - [x] Investigate various libraries and how they fit into Fledex. I looked at various different libraries (`erlcron`, `sched_ex`, `exq_scheduler`, `ecron`, ...), but none really fulfils the needs :-( `SchedEx` is the one that is simple and comes closest. Therefore the plan is to take it (it's MIT license), modify it, and integrate it into Fledex
      - [ ] It's not possible to inject a context to the job, because you either have to provide an `{M, F, [Args]}` or a `(-> any())` function. The former is not possible, since we don't have amodule (but just an anonymous function) and the latter is not possible, because we can't pass in any argument :-(. We would need to extend Quantum to accept an {F, [Args]}
  - [ ] Enable Telemetry? (v0.8)
  - [ ] Add support for WS2811/12/13/14/15 LED strips controlled through phase modulation. (v0.8)
  - [ ] Get it working on AtomVM (v0.9)
  - [ ] Add Perlin noise functions (see: https://hackaday.com/2019/12/28/led-flame-illuminates-the-beauty-of-noise/, https://hexdocs.pm/perlin/Perlin.html) (v0.9)
  - [ ] Clustering (v0.8)
    - [ ] Rethink the clusering and check whether the new livebook API endpoints might make it easier to cluster. Currently it seems to be quite complicated.
    - [ ] Provide examples on how to cluster
    - [ ] Add an example where several nodes are connected to transfer pubsub messages accross nodes
    - [ ] Implement music beat through clustering
  - [ ] setting up livebook (a really working version) on windows is anything than easy :-( Can we do something about it? Investigate (v0.9)
  - [ ] Create smartcells? (v1.x)
- [ ] License
  - [x] Ensure everything can be under an FSF approved open source license (see https://spdx.org/licenses/)
    - [x] wiki colors (v0.7)
    - [x] ral colors (v0.7)
    - [x] cone image (v0.7)
- [ ] Increase consumption
  - [ ] Create a video (once v0.6 is released)
  - [ ] Migrate outstanding TODOs to github (v0.8)
  - [ ] Publish/announce on Elixirforum (v0.8)
  - [ ] Get the library into nerves-livebook (v0.8)
  - [ ] Move repository to its own org (fledex as an org is already taken, but fled-ex is free and I took it) (v0.8) <-- Announce this in the next release notes that this will happen?
  - [ ] Create a github pages site for the project (v0.8)
