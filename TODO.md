<!--
Copyright 2023-2026, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
Even though this library is published, there are things I still want to do before I consider this as really done. Here the outstanding tasks that I can think of.

# Tasks
- [ ] Documentation
  - [ ] Add a livebook with coordinator examples (v0.8) <-- WIP
  - [ ] Update documentation with the Supervision tree (v0.8)
  - [ ] hardware setup (analogy with a bus letting 24 passangers off the bus at every led-bus-stop). Create a comprehensive write-up (v0.8)
- [ ] Testing
  - [ ] Test the new ws2812 driver on real hardware (v0.8)
  - [ ] Add tests for the Clock component (v0.8)
  - [ ] Add tests for the Thermometer component (v0.8)
- [ ] Cleanup
  - [x] We should be able to replace the `Animation.Manager` config splitting with the `Enum.group_by` function (v0.8)
  - [ ] Make sure that all the job options are correctly honored (adjust documentation if necessary) (v0.8)
  - [ ] Rethink whether we really want to create a `Fledex.Config.Data` module or we should store the information in a GenServer, or even better in an ETS table. The issue with the GenServer is that we need to start a server (which is not ideal in all situations). But maybe that's not soo bad. (v0.9)
- [ ] Missing functionality
  - [ ] Put some more effort into the coordinator to make it work well (v0.8)
  - [ ] Enable Telemetry? (v0.8)
    - [ ] Switch also the `fledex_scheduler` stats to telemetry (v0.8)
  - [x] Add support for WS2811/12/13/14/15 LED strips through the SPI port (v0.8)
  - [ ] Add support for white leds in the various WS281x led strips
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
- [ ] Security
  - [ ] Investigate whether the creation of atoms in events can be avoided, example in trigger_names? (v0.9)
- [ ] Increase consumption
  - [ ] Create a video (once v0.7 is released)
  - [ ] Migrate outstanding TODOs to github (v0.8)
  - [ ] Publish/announce on Elixirforum (v0.8)
  - [ ] Get the library into nerves-livebook (v0.8)
  - [ ] Move repository to its own org (fledex as an org is already taken, but fled-ex is free and I took it) (v0.8) <-- Announce this in the next release notes that this will happen?
  - [ ] Create a github pages site for the project (v0.8)
