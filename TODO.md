# Intro
Even though this library is published, there are things I still want to do before I consider this
as really done. Here the outstanding tasks that I can think of.
# Tasks
- [ ] Add installation instructions
- [x] Provide several notebook examples (test env, prod)
  - [ ] This requires still some minor modifications once the next version is published to not load the code from my local drive (v0.3)
- [ ] Perform an extra round of testing on hardware (v0.3) 
- [ ] Enable Telemetry? (v0.5)
- [ ] Connect everything into a supervision tree (to make it more robust) (v0.4)
- [ ] Get the library into nerves-livebook (v0.7)
- [ ] Add proper API/module documentation (v0.3)
- [ ] Add documentation on how to connect the LED strip to a RaspberryPi Zero (with and without level shifter).
      This could be part of the first example (v0.3)
- [ ] Finish the dsl livebook example (mostly done, but the send_config part is not done yet) (v0.2)
- [ ] Create a dsl (domain specific language) to (finally) easily program strips
  - [x] Define an led strip (v0.2)
  - [x] Define a live_loop (v0.2)
  - [x] Add more macro tests (v0.2)
  - [ ] Extend the Fledex macros to allow easy configuration with a config macro (v0.3)
- [ ] Add an example where several nodes are connected to transfer pubsub messages accross nodes (v0.3)
- [x] Change the `Leds`' `new` function to an `leds` function. That makes it more natural to read if the Leds module gets imported. (v0.2)
- [ ] Remove unnecessary imports in the examples (v0.3)
- [ ] Add type specs (v0.3)
- [ ] Add more unit tests, check --cover (v0.3)
- [ ] Create foundation for a led-component-library that enables defining reusable led components. For example both the clock as well as the weather example have a scale it would be easy to define those as components that would make it easier to defining certain aspects (v0.5)
- [ ] Upgrade to a final version of circuit_spi v2.0 (whenever available)
