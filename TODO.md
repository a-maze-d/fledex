# Intro
Even though this library is published, there are things I still want to do before I consider this
as really done. Here the outstanding tasks that I can think of.

# Tasks
- [ ] Documentation
  - [x] Provide several notebook examples (v0.2)
  - [ ] Finish the dsl livebook example (mostly done, but the send_config part is not done yet) (v0.3)
  - [ ] Add proper API/module documentation (v0.3)
  - [ ] Add type specs (v0.3)
  - [ ] Improve hexdocs (add livebooks, create cheatsheet) (v0.3)
  - [ ] Add documentation on how to connect the LED strip to a RaspberryPi Zero (with and without level shifter).This could be part of the first example (v0.3 & v0.4)
  - [ ] Add installation instructions (v0.4)
- [ ] Create a dsl (domain specific language) to (finally) easily program strips
  - [x] Define an led strip (v0.2)
  - [x] Define a live_loop (v0.2)
  - [x] Add more macro tests (v0.2)
  - [ ] Extend the Fledex macros to allow easy configuration with a config macro (v0.3)
- [ ] Clustering
  - [ ] Provide examples on how to cluster (v0.3)
  - [ ] Add an example where several nodes are connected to transfer pubsub messages accross nodes (v0.3)
  - [ ] Create a driver that outputs through pubsub (on one node) and an animation that consumes those (this allows to connect remote livebooks to a physical led strip) (v0.4)
- [ ] Cleanup
  - [x] Change the `Leds`' `new` function to an `leds` function. That makes it more natural to read if the Leds module gets imported. (v0.2)
  - [x] Remove unnecessary imports in the examples (v0.2)
  - [x] Add more unit tests, check mix coveralls.html (v0.2)
  - [x] Upgrade to a final version of circuit_spi v2.0 (whenever available) (v0.2)
  - [x] import the Fledex.Color.Names so colors can easily be defined through function calls instead of atom names )v0.3)
  - [ ] Fix flaxy tests (see TODOs) (v0.3)
  - [ ] Perform an extra round of testing on hardware (v0.3)
  - [ ] Enable Telemetry? (v0.5)
  - [ ] Upgrade to a hex released version of circuits_sim as soon as available (v0.?)
- [ ] Missing functionality
  - [ ] see the project plan that was planned out with my son, we are not quite there yet
  - [ ] Connect everything into a supervision tree (to make it more robust) (v0.4)
[ ] LED-component library
  - [ ] Create foundation for a led-component-library that enables defining reusable led components. For example both the clock as well as the weather example have a scale it would be easy to define those as components that would make it easier to defining certain aspects (v0.5)
- [ ] Increase consumption
  - [ ] Use in school project (v0.4)
  - [ ] Publish/announce on Elixirforum (v0.5 or v0.6)
  - [ ] Get the library into nerves-livebook (v0.7)
