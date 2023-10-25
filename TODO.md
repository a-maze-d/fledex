# Intro
Even though this library is published, there are things I still want to do before I consider this
as really done. Here the outstanding tasks that I can think of.
# Tasks
- [ ] Add installation instructions
- [ ] Provide several notebook examples (test env, prod)
- [x] Perform an extra round of testing (also on hardware)
- [ ] Change most configs to keyword lists instead of maps?
- [ ] Enable Telemetry
- [ ] Push the client code so that live updates would be possible (after every loop an update could be sent)
      This is now enabled through the `LedAnimator` and `LedAnimationManager` module, but it's not complete enough to tick it off.
- [ ] Create a simple pubsub system, so that we can publish and listen to our triggers
- [ ] Create a dsl (domain specific language) to (finally) easily program strips
- [ ] Conncet everything into a supervision tree (to make it more robust)
- [ ] Change the name registration from atoms to strings (to avoid garbage collection issues)
- [ ] Get the library into nerves-livebook
- [ ] Add proper API/module documentation
- [ ] Add documentation on how to connect the LED strip to a RaspberryPi Zero (with and without level shifter)
- [x] Cleanup files
- [x] Publish to hex (v1.1 has been published)
- [x] Fix all credo issues by running `mix credo --all`
