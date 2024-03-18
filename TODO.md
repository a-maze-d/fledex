<!--
Copyright 2023, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
Even though this library is published, there are things I still want to do before I consider this as really done. Here the outstanding tasks that I can think of.

# Tasks
- [ ] Documentation
  - [ ] Improve hexdocs
    - [ ] create cheatsheet (v0.4)
  - [x] Add documentation on how to connect the LED strip to a RaspberryPi Zero (v0.4) 
  - [ ] Add installation instructions (v0.4)
  - [x] Add documentation on how to conncet the LED strip to a RPI with a level shifter (v0.7)
        https://electronics.stackexchange.com/questions/82104/single-transistor-level-up-shifter/82112#82112
- [ ] Testing
  - [ ] Add more error handling scenarios (v0.4)
- [ ] Cleanup
  - [x] add Copyright comment into every file (make reuse green) (v0.4)
  - [ ] Improve the Fledex configuration. The fledex_config/0 function feels very wrong (rethink the animator split up. Also effects raise the questions whether static "animations" should really be so static, since the effect would have any real effect on them) (v0.4)
  - [ ] Improve the LedsDriver config (v0.4)
  - [ ] Fix flaky tests (see TODOs) (v0.4)
  - [ ] Perform an extra round of testing on hardware (v0.4)
  - [ ] Enable Telemetry? (v0.5)
  - [ ] Upgrade to a hex released version of circuits_sim as soon as available (v0.?)
- [ ] Missing functionality
  - [ ] see the project plan that was planned out with my son, we are not quite there yet (v0.4?)
  - [ ] Add the possibility to clear the LEDs when initializing the LedsDriver
  - [ ] Connect everything into a supervision tree (to make it more robust) (v0.4)
  - [x] Use protocols ?
    - [x] ??? animations & components? <-- no, only behaviour
  - [x] Create a dsl (domain specific language) to (finally) easily program strips
    - [x] Extend the Fledex macros to allow easy configuration with a config macro (v0.4)
    - [x] Allow several animations behind a single effect (v0.4), i.e.:
    ```elixir
    effect Rotation do
      animation :first_animation do
        # something
      end
      animation :second_animation do
        # something else
      end
    end
    ```
  - [ ] Clustering
    - [ ] create an animation that consumes those (this allows to connect remote livebooks to a physical led strip. CAUTION: protect against loops!) (v0.5)
    - [ ] Provide examples on how to cluster (v0.5)
    - [ ] Add an example where several nodes are connected to transfer pubsub messages accross nodes (v0.5)
  - [ ] LED-component library
    - [ ] Create foundation for a led-component-library that enables defining reusable led components. For example both the clock as well as the weather example have a scale it would be easy to define those as components that would make it easier to defining certain aspects (v0.5)
- [ ] Increase consumption
  - [ ] Use in school project (v0.4)
  - [ ] Talk on meetups? (v0.5 or v0.6)
  - [ ] Migrate outstanding TODOs to github (v0.6?)
  - [ ] Publish/announce on Elixirforum (v0.6)
  - [ ] Get the library into nerves-livebook (v0.7)
  - [ ] Design a project logo (v0.5)
  - [ ] Create a video (v0.5)
