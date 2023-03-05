# Intro
This is a list of tasks that should be done before we can consider it as a 0.1 version
and being ready for publication

# Tasks
- [x] Allow multi LedStripDriver modules at the same time (requires also reworking the LedDriver config to namespace the configs)
- [x] Add tests for the LedStripDriver modules (that changes really work)
- [x] Rename leds_name to namespace
- [x] Allow setting color correction to the LedStripDriver (I think every strip driver should get a different one)
  - [x] Kino
  - [x] SPI
- [ ] Copyright & License stuff
  - [x] Add copyright notice in every file (decided to not do this)
  - [x] contribution policy file
  - [x] CLA, https://contributoragreements.org/ca-cla-chooser/
  - [ ] CLA form https://github.com/cla-assistant/cla-assistant or https://github.com/contributor-assistant/github-action
- [x] Add a CREDITs file
- [x] Write a decently good README file
- [x] Replace 256 colors file with an alternative due to licensing reasons
- [x] Add proper Readme including examples
- [x] Replace the nimble_csv with an own implementation to reduce the dependencies
- [ ] Add installation instructions
- [ ] Provide several notebook examples (test env, prod)
- [ ] Perform an extra round of testing (also on hardware)
- [ ] Create a new TODO list which is ready for publication
  - [ ] Change most configs to lists instead of maps?
  - [ ] Enable Telemetry
  - [ ] Push the client code so that live updates would be possible (after every loop an update could be sent)
  - [ ] Get the library into nerves-livebook
  - [ ] Add proper API/module documentation
  - [ ] Add documentation on how to connect the LED strip to a RaspberryPi Zero (with and without level shifter)
- [ ] Cleanup files
- [x] Check use of fledex as a project name
- [x] Resolve all code TODOs
- [x] Tag git repository
- [x] Push to github
  - [x] create a github project
- [ ] Publish to hex
  - [x] Create a hex account

