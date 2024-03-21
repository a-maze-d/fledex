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
  - [x] Improve the Fledex configuration. The fledex_config/0 function feels very wrong (rethink the animator split up. Also effects raise the questions whether static "animations" should really be so static, since the effect would have any real effect on them) (v0.4) <-- DONE: static is only a convenience, they need to be "animated" too. A Coordinator will be introduced to coordinate animations. The sequencer I added before is likely to disappear again. Also the animation state will probably be implemented through pubsub instead of return value. This allows the coordinator to pick those up. We have to be careful though to only publish state changes. All envisaged changed will be tracked independently.
  - [ ] Improve the LedsDriver config (v0.4)
  - [x] Fix flaky tests (see TODOs) (v0.4) <-- haven't seen any of those anymore
  - [ ] Perform an extra round of testing on hardware (v0.4)
  - [ ] Enable Telemetry? (v0.5)
  - [x] Upgrade to a hex released version of circuits_sim as soon as available (v0.?)
- [ ] Missing functionality
  - [x] see the project plan that was planned out with my son, we are not quite there yet (v0.4)
  - [x] review the ideas.md document to see whether all ideas have been implemented (v0.4)
  - [x] improve on the effect state and component state handling. It's currently possible, but not super smooth and it's also difficult to avoid conflicts between different animations/effect/components <-- see my comment above about rethinking the config. This covers this aspect too.
  - [x] Create a sequencer effect that runs one effect before switching to the next effect. Maybe we  can replace the wanish and reappaer effect with 2 distinct effects this way and each of them being simpler. (v0.4) NOTE: This will not be done. I gave it some more thoughts and instead of a sequencer I will implement support for a coordinator that can control individual animations/effects.
  - [ ] Create support for a coordinator (that can control individual animations and effects. Effects will have to notify back their state)
  - [ ] Create support for a cron-manager (that allows running jobs, like the one we have in the weather station example and thereby no need to handcraft anything)
  - [ ] Add the possibility to clear the LEDs when initializing the LedsDriver (v0.4)
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
    - [x] Create foundation for a led-component-library that enables defining reusable led components. For example both the clock as well as the weather example have a scale it would be easy to define those as components that would make it easier to defining certain aspects (v0.5) Note: this should now be possible, since we have a component macro which simply returns animation configs. The above improvements should help to make this more smooth
- [ ] Increase consumption
  - [ ] Use in school project (v0.4)
  - [ ] Design a project logo (v0.5)
  - [ ] Create a video (v0.5)
  - [ ] Talk on meetups? (v0.5 or v0.6)
  - [ ] Migrate outstanding TODOs to github (v0.6?)
  - [ ] Publish/announce on Elixirforum (v0.6)
  - [ ] Get the library into nerves-livebook (v0.7)
  - [ ] Design a project logo (v0.5)
  - [ ] Create a video (v0.5)
