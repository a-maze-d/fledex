<!--
Copyright 2023-2024, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
Even though this library is published, there are things I still want to do before I consider this as really done. Here the outstanding tasks that I can think of.

# Tasks
- [ ] Documentation
  - [ ] Add a livebook with coordinator examples (v0.6)
  - [ ] Update the cheatsheet (v0.6)
    - [ ] Coordinator missing
    - [ ] version number wrong
  - [ ] Add installation instructions (v0.6)
  - [ ] Add information about color correction (section 3b) (v0.6)
  - [ ] change the doc structure? so that links don't get so easily broken? (v0.6)
  - [ ] Useful to provide a full story about colors (additive / subtractive colors), hardware setup (analogy with a bus letting 24 passangers off the bus at every led-bus-stop). Create a comprehensive write-up (v0.6/0.7)
- [ ] Testing
  - [ ] Add more error handling scenarios (v0.6)
  - [ ] Add tests for the Clock and Thermometer components (v0.6)
- [ ] Cleanup
  - [x] Clean up commented out code (v0.6)
  - [ ] Restructure the Animation code (v0.6)
    - [x] `AnimatorBase` doesn't make too much sense. 
    - [x] Review documentation
    - [ ] The `Animator.config_t` structure should at least partially be defined by the manager (at least the component should get it from there, since it's allowed to also add `:coordinator` and `:job` to it)
    - [ ] We probably want to remove some of the `optional` attributes in the `Animator.config_t` structure
    - [x] Does the `AnimatorInterface` still make sense? No, break out into a Utils module
  - [ ] Do we want to create a Utily class for Components, so that the name creation is simplified? (v0.6)
- [ ] Enable Telemetry? (v0.7)
- [ ] Missing functionality
  - [ ] Add a default `led_strip` driver that can be configured through the config (v0.6)
  - [ ] Connect everything into a supervision tree (to make it more robust) (v0.6)
  - [ ] setting up livebook (a really working version) on windows is anything than easy :-( Can we do something about it? Investigate (v0.7) 
  - [ ] Add support for WS2811/12/13/14/15 LED strips controlled through phase modulation.
  - [ ] Clustering (v0.7)
    - [ ] Rethink the clusering and check whether the new livebook API endpoints might make it easier to cluster. Currently it seems to be quite complicated.
    - [ ] Provide examples on how to cluster
    - [ ] Add an example where several nodes are connected to transfer pubsub messages accross nodes
    - [ ] Implement music beat through clustering
  - [ ] Define functions that are valid in the correct scope? (v0.7)
  - [ ] Create smartcells (v0.8)
  - [ ] Do we need to have language packs that allows to adjust to other languages? it would be quite easy with some `defdelegate`  At least for: (v0.9). Probably "NO", but I will reflect a bit more before closing this one!
- [ ] Increase consumption
  - [ ] Create a video (v0.6)
  - [ ] Migrate outstanding TODOs to github (v0.6?)
  - [ ] Publish/announce on Elixirforum (v0.6)
  - [ ] Get the library into nerves-livebook (v0.7)
