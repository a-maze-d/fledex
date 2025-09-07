<!--
Copyright 2023-2024, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
Even though this library is published, there are things I still want to do before I consider this as really done. Here the outstanding tasks that I can think of.

# Tasks
- [ ] Documentation
  - [x] Add information about color correction (section 3b) (v0.7)
  - [ ] Document the driver options (v0.7)
  - [x] Improve API documentation (v0.7)
  - [ ] hardware setup (analogy with a bus letting 24 passangers off the bus at every led-bus-stop). Create a comprehensive write-up (v0.7)
  - [ ] Add a livebook with coordinator examples (v0.7)
  - [ ] Update the cheatsheet with coordinator info (v0.7)
  - [ ] Update documentation with the Supervision tree (v0.7)
- [ ] Testing
  - [ ] Add tests for the Clock and Thermometer components (v0.7)
- [ ] Cleanup
  - [ ] Cleanup the color conversion functions. There are a lot of unused parts, providing flexibility that is not required.
  - [ ] Add more guards to functions to make them more robust (v0.7)
  - [ ] All Color name modules have the same interface (through the DSL it's even enforced). Let's make this more explicit by introducting a Color.Names.Interface with the appropriate callbacks (v0.7)
- [ ] Missing functionality
  - [ ] The Job should (at least appear) to be connected to the LedStrip (v0.7)
  - [ ] Replace Quantum with SchedEx? https://hexdocs.pm/sched_ex/readme.html (v0.7)
  - [ ] we start things through the Supervisor, but we don't shut things down through it (v0.7)
  - [ ] We have the `Fledex.Color` protocol, but we actually don't make use of its type. This is maybe also a good opportunity to rethink on how we handle colors in general. Maybe we should define everything as `Fledex.Color` and encapsulate CSS, SVG, RAL colours in their own struct to then have the protocol implemented for them. (v0.7)
  Other advantages:
  - [ ] convert the rgb to other color spaces (in the various color name modules) (v0.7)
  - [ ] Put some more effort into the coordinator to make it working well (v0.7)
  - [ ] Enable Telemetry? (v0.8)
  - [ ] should the `:config` driver not only return the config but the strip_name too?
  - [ ] setting up livebook (a really working version) on windows is anything than easy :-( Can we do something about it? Investigate (v0.7)
  - [ ] Add support for WS2811/12/13/14/15 LED strips controlled through phase modulation. (v0.7)
  - [ ] Clustering (v0.8)
    - [ ] Rethink the clusering and check whether the new livebook API endpoints might make it easier to cluster. Currently it seems to be quite complicated.
    - [ ] Provide examples on how to cluster
    - [ ] Add an example where several nodes are connected to transfer pubsub messages accross nodes
    - [ ] Implement music beat through clustering
  - [ ] Create smartcells? (v1.x)
- [ ] License
  - [ ] Ensure everything can be under an FSF approved open source license (see https://spdx.org/licenses/)
    - [ ] wiki colors (v0.7)
    - [ ] ral colors (v0.7)
    - [x] cone image (v0.7)
- [ ] Increase consumption
  - [ ] Create a video (once v0.6 is released)
  - [ ] Migrate outstanding TODOs to github (v0.7)
  - [ ] Publish/announce on Elixirforum (v0.7)
  - [ ] Get the library into nerves-livebook (v0.7)
- [ ] Bugs (currently none known)
