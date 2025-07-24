<!--
Copyright 2023-2024, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
Even though this library is published, there are things I still want to do before I consider this as really done. Here the outstanding tasks that I can think of.

# Tasks
- [ ] Documentation
  - [x] version number wrong in the cheatsheet is wrong (v0.6)
  - [x] Add installation instructions (v0.6)
  - [x] change the doc structure? so that links don't get so easily broken? (v0.6)
  - [x] Useful to provide a full story about colors (additive / subtractive colors) (v0.6)
  - [ ] Add information about color correction (section 3b) (v0.7)
  - [ ] Document the driver options (v0.7)
  - [ ] hardware setup (analogy with a bus letting 24 passangers off the bus at every led-bus-stop). Create a comprehensive write-up (v0.7)
  - [ ] Add a livebook with coordinator examples (v0.7)
  - [ ] Update the cheatsheet with coordinator info (v0.7)
  - [ ] Update documentation with the Supervision tree (v0.7)
- [ ] Testing
  - [x] Add more error handling scenarios (v0.6)
  - [ ] Add tests for the Clock and Thermometer components (v0.7)
- [x] Cleanup
  - [x] Clean up commented out code (v0.6)
  - [x] Restructure the Animation code (v0.6)
    - [x] `AnimatorBase` doesn't make too much sense. 
    - [x] Review documentation
    - [x] The `Animator.config_t` structure should at least partially be defined by the manager (at least the component should get it from there, since it's allowed to also add `:coordinator` and `:job` to it). This was just an oversight, fixed now!
    - [x] We probably want to remove some of the `optional` attributes in the `Animator.config_t` structure
    - [x] Rename the Manager.config_t() type (remove the plural s)
    - [x] Does the `AnimatorInterface` still make sense? No, break out into a Utils module
  - [x] Do we want to create a Utily class for Components, so that the name creation is simplified? (v0.6)
  - [x] enable testing with more elixir versions 
    - [x] decide on what to do with the color stuff that seems to be broken with the new- Elixir version
  - [x] align the `terminate`, `shutdown`, `stop` functions to be consistent
  - [x] cleanup the argument order to be more consistent between Animator, Coordinator and LedStrip
  - [x] Remove the `WorkerSupervisor`. It doesn't seem to have any value anymroe
  - [x] cleanup the via_tuple stuff once coordinator is done (move Utils to Supervisor? yes moved)
  - [x] Do we really need to use the `Leds.send` function in the `Animator`. Moving it to `LedStrip`
  - [/] Can we reuse the same registry for PubSub and for our workers? (v0.6) No, we can't because we have different requirements. So we have to live with two registries
  - decide on what to do with the effect states
  - [ ] Add more guards to functions to make them more robust (v0.7)
  - [x] Check the build version. We state Elixir version `~>1.14` in the `mix.exs` file, but we only build it with `1.17.x` and `1.18.x` in our `elixir.yml`. We should align those two. Limiting to the min version to be the same as nerves-livebook, because that's what I really target.
- [ ] Missing functionality
  - [/] Add a default `led_strip` driver that can be configured through the config (v0.6)
        I experimented with this idea, but it really doesn't give a real benefit. Therefore dropped it again.
  - [x] Connect everything into a supervision tree (to make it more robust) (v0.6)
    - [x] handle all the TODOs (done, for those related to the supervisor changes)
    - [x] Add logs to starting/shutting down of processes
    - [x] add documentation (livebook, `@doc`, `@module_doc`)
    - [x] add negative tests (killing some service)
    - [x] Create commit log
    - [x] Cleanup code from commented out stuff
    - [x] Cleanup code from debug stuff
    - [x] extra round of testing
    - [x] check specs, Credo, ...
    - [x] The Animator shoudl be connected to the LedStrip. Otherwise we get the wrong behavior
    - [x] The Coordinator should be connected to the LedStrip, otherwise it would be awkward
    - [x] Fix livebooks
      - [x] livebook 2
      - [x] livebook 2b
      - [x] livebook 3
      - [x] livebook 3b
      - [x] livebook 4
      - [x] livebook 5
      - [x] livebook 6
      - [x] livebook 7
      - [x] livebook 8
      - [x] livebook 9 
  - [ ] The Job should (at least appear) to be connected to the LedStrip (v0.7)
  - [ ] Replace Quantum with SchedEx? https://hexdocs.pm/sched_ex/readme.html (v0.7)
  - [ ] we start things through the Supervisor, but we don't shut things down through it (v0.7)
  - [ ] We have the `Fledex.Color` protocol, but we actually don't make use of its type. This is maybe also a good opportunity to rethink on how we handle colors in general. Maybe we should define everything as `Fledex.Color` and encapsulate CSS, SVG, RAL colours in their own struct to then have the protocol implemented for them. (v0.7)
  Other advantages:
    - [x] This should make the `CalcUtils.split_into_subpixels` unnecessary (v0.6)
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
  - [/] Do we need to have language packs that allows to adjust to other languages? it would be quite easy with some `defdelegate`  At least for: (v0.9). Probably "NO", but I will reflect a bit more before closing this one! Concluded that "No".
- [x] Bugs:
  - [x] The documentation is not perfect. The defdelegate works fine, but attaching the documentation does not always work. It sometimes refers to the original file which I don't really want (v0.6)
- [ ] Increase consumption
  - [ ] Create a video (once v0.6 is released)
  - [ ] Migrate outstanding TODOs to github (v0.7)
  - [ ] Publish/announce on Elixirforum (v0.7)
  - [ ] Get the library into nerves-livebook (v0.7)
