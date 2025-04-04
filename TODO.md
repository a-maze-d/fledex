<!--
Copyright 2023-2024, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
Even though this library is published, there are things I still want to do before I consider this as really done. Here the outstanding tasks that I can think of.

# Tasks
- [ ] Documentation
  - [x] Add Branching sections in the livebooks to separate things that don't need to be together? (v0.5)
  - [x] Update the README.md (v0.5)
  - [ ] Add installation instructions (v0.5)
  - [x] Update the architectural overview to adjust to the new driver approach (v0.5)
  - [x] Update Cheatsheet with new driver approach (v0.5)
  - [x] Mark the livbooks so that it becomes clear what kind they are (internal, background, usage,...) (v0.5)
  - [x] Check that all livebooks are mentioned in the README.md (v0.5)
  - [ ] change the doc structure? so that links don't get so easily broken? (v0.6)
- [ ] Testing
  - [x] Perform an extra round of testing on hardware (v0.4)
  - [x] Fix the issue in the livebooks that `broadcast_trigger/1` gets called directly now, since the function gets imported (v0.4)
  - [x] Go through all Livebooks and make sure they all work after all the refactorings, there seem to be some minor issues. (v0.4) 
  - [x] parse the config for missing functions, so that errors can be detected early on, instead of failing when trying to paint things (v0.5)
  - [ ] Add more error handling scenarios (v0.6)
- [x] Driver improvements
  - [x] Fix the LedsDriver.reinit so that a reconfiguration of drivers is possible. Currently the new config is not passed in (v0.5)
    - [x] Give it an extra test drive
    - [x] Fix the SPI driver so that it compares the settings (kind of fixed, we always reconnect instead)
  - [x] Improve the LedsDriver config (v0.5)
    - [x] Cleanup
    - [x] Update the livebooks
    - [x] Add some more tests
    - [x] Remove the "change_config" function
    - [x] Some extensive testing
    - [x] Work down the TODOs (related to the driver changes)
- [x] Cleanup
  - [x] Upgrade dependencies [v0.5]
  - [x] `LedStrip`  is partially directly called in the `Manager` (v0.5)
  - [x] restructure the `Fledex.Color.Names` so that the compilcation doesn't take that much time and that we can add easier more colors. Done, but the compilation didn't get faster, by adding more colors, it even got slower. But I still leave it.
  - [x] The `Leds` code contains a lot of aspects that shouldn't be necessary anymore (like check that the namespace is defined, that the process is up and running, ...). This does not only make the code over complicated, but also will have a performance impact. We should clean this up. 
  - [x] the `Leds` rainbow function take currently a map, but it would be better to take a keyword list. (v0.5)
  - [x] Maybe even change the light function and move the offset and repeat to be opts parameters (v0.5)
  - [x] Use a keyword list for the Leds.send optional parameters (v0.5)
  - [x] have `Fledex.Color` protocol for `to_colorint` conversion? This could avoid some of the cyclic dependencies that we are seeing (v0.5)
- [ ] Enable Telemetry? (v0.7)
- [ ] Missing functionality
  - [x] Add the possibility to clear the LEDs when initializing the LedsDriver. This should be a feature fo the Spi Driver (v0.5)
  - [x] Create support for a coordinator (that can control individual animations and effects). (v0.5) 
  - [x] Update effects to make use of the coordinator functionality by reporting back their state through PubSub (v0.5)
  - [ ] Update livebook examples how animations, effects, ... can be coordinated (v0.5)
  - [ ] Add a default `led_strip` driver that can be configured through the config (v0.6)
  - [ ] Connect everything into a supervision tree (to make it more robust) (v0.6)
  - [ ] Clustering (v0.7)
    - [ ] Rethink the clusering and check whether the new livebook API endpoints might make it easier to cluster. Currently it seems to be quite complicated.
    - [ ] Provide examples on how to cluster
    - [ ] Add an example where several nodes are connected to transfer pubsub messages accross nodes
    - [ ] Implement music beat through clustering
  - [ ] Define functions that are valid in the correct scope? (v0.7)
  - [ ] Create smartcells (v0.8)
  - [ ] Do we need to have language packs that allows to adjust to other languages? it would be quite easy with some `defdelegate`  At least for: (v0.9). Probably "NO", but I will reflect a bit more before closing this one!
- [ ] Increase consumption
  - [x] Use in school project (v0.4). The learnings:
    - [ ] setting up livebook (a really working version) on windows is anything than easy :-(Can we do something about it? Investigate (v0.7) 
    - [x] Reconfiguration of the strip is an important thing (see TODO item above)
    - [ ] Useful to provide a full story about colors (additive / subtractive colors), hardware setup (analogy with a bus letting 24 passangers off the bus at every led-bus-stop). Create a comprehensive write-up (v0.6)
  - [x] Talk on meetup (v0.5)
  - [ ] Create a video (v0.6)
  - [ ] Migrate outstanding TODOs to github (v0.6?)
  - [ ] Publish/announce on Elixirforum (v0.6)
  - [ ] Get the library into nerves-livebook (v0.7)
