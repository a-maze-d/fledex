<!--
Copyright 2023-2024, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
Even though this library is published, there are things I still want to do before I consider this as really done. Here the outstanding tasks that I can think of.

# Tasks
- [ ] Documentation
  - [ ] change the doc structure? so that links don't get so easily broken? (v0.6)
  - [ ] Add installation instructions (v0.5)
  - [x] Add Branching sections in the livebooks to separate things that don't need to be together? (v0.5)
- [ ] Testing
  - [x] Perform an extra round of testing on hardware (v0.4)
  - [x] Fix the issue in the livebooks that `simple_broadcast/1` gets called directly now, since the function gets imported (v0.4)
  - [x] Go through all Livebooks and make sure they all work after all the refactorings, there seem to be some minor issues. (v0.4) 
  - [ ] Add more error handling scenarios (v0.5)
  - [x] parse the config for missing functions, so that errors can be detected early on, instead of failing when trying to paint things (v0.5)
- [ ] Driver improvements
  - [x] Fix the LedsDriver.reinit so that a reconfiguration of drivers is possible. Currently the new config is not passed in (v0.5)
    - [ ] Give it an extra test drive
    - [x] Fix the SPI driver so that it compares the settings
  - [x] Improve the LedsDriver config (v0.5)
    - [ ] Update the documentation
    - [x] Cleanup
    - [x] Update the livebooks
    - [ ] Update the README.md
    - [x] Add some more tests
    - [x] Remove the "change_config" function
    - [x] Some extensive testing
    - [x] Work down the TODOs (related to the driver changes)
- [ ] Cleanup
  - [x] Upgrade dependencies [v0.5]
  - [x] `LedStrip`  is partially directly called in the `Manager` (v0.5)
  - [ ] Enable Telemetry? (v0.7)
- [ ] Missing functionality
  - [ ] Add the possibility to clear the LEDs when initializing the LedsDriver. This should be a feature fo the Spi Driver (v0.5)
  - [ ] Connect everything into a supervision tree (to make it more robust) (v0.5)
  - [ ] Create support for a coordinator (that can control individual animations and effects. Effects will have to notify back their state) (v0.6)
  - [ ] Clustering
    - [ ] Rethink the clusering and check whether the new livebook API endpoints might make it easier to cluster. Currently it seems to be quite complicated.
    - [ ] Provide examples on how to cluster (v0.5)
    - [ ] Add an example where several nodes are connected to transfer pubsub messages accross nodes (v0.5)
    - [ ] Implement music beat through clustering
  - [ ] Do we need to have language packs that allows to adjust to other languages? At least for color it would be quite easy with some `defdelegate`
  - [ ] Create smartcells (v0.6)
- [ ] Increase consumption
  - [x] Use in school project (v0.4). The learnings:
    - [ ] setting up livebook (a really working version) on windows is anything than easy :-( Can we do something about it? Investigate (v0.5?) 
    - [x] Reconfiguration of the strip is an important thing (see TODO item above)
    - [ ] Useful to provide a full story about colors (additive / subtractive colors), hardware setup (analogy with a bus letting 24 passangers off the bus at every led-bus-stop). Create a comprehensive write-up
  - [ ] Create a video (v0.5)
  - [ ] Talk on meetups? (v0.5 or v0.6)
  - [ ] Migrate outstanding TODOs to github (v0.6?)
  - [ ] Publish/announce on Elixirforum (v0.6)
  - [ ] Get the library into nerves-livebook (v0.7)
  - [ ] Create a video (v0.5)
