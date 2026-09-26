<!--
Copyright 2023-2026, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
Even though this library is published, there are things I still want to do before I consider this as really done. Here the outstanding tasks that I can think of.

# Tasks

## Done

## Documentation
- [ ] Add a livebook with coordinator examples (v0.9) <-- WIP
- [ ] Update documentation with the Supervision tree (v0.9)
- [ ] [School] hardware setup (analogy with a bus letting 24 passangers off the bus at every led-bus-stop). Create a comprehensive write-up (v0.9)
- [ ] Write a tutorial like description? (v1.0)

## Testing
- [ ] Add tests for the Clock component (v0.9)
- [ ] Add tests for the Thermometer component (v0.9)
- [ ] Hardware testing with WS2805, WS2811, WS2813, WS2814, and WS2815 strips (whenever I get appropriate strips)

## Cleanup
- [ ] Cleanup the Kino driver to not run into conflicts with the Kino library? (v0.9)
- [] Migrate to Color (https://github.com/elixir-image/color)? (v0.9). Decided to not migrate, but to take over the extra white-led driving functions.
- [ ] Make sure that all the job options are correctly honored (adjust documentation if necessary) (v0.9)
- [ ] Rethink whether we really want to create a `Fledex.Config.Data` module or we should store the information in a GenServer/Registry/ETS table. The issue with the GenServer is that we need to start a server (which is not ideal in all situations). Also we need to make sure it works also for atomvm. But maybe that's not soo bad, but let's revisit. (v0.9)
- [ ] Should the Application be removed (so it's really a library)


## Bugs
- [ ] It looks like the offset can in some circumstances be zero and in others it can not. It's not consistent. Also for animations it's easier if the offset is allowed to be zero. (0.9)
  - [ ] `Leds.light` sets it to 1 (by default) (and deducts 1 in the calculation). 
  - [ ] I think I did that so the index calculation is easy
  - [ ] Realizing that the `index = max(index, 1)` is a stupid idea, because we do allow indicies to go out of range (thus, negative ones should be allowed). This might be interesting especially if we talk about rotations, even though it would mean to rethink the whole rotation part.
  - [ ] This will have an impact on `Leds.repeat`. I guess everywhere were we manipulate the index.
- [ ] On a WS2812 strip there was a mis-coloration on the first LED. Are some startup timings wrong? It was a simple RGB. It was during a presentation, so could have been two strip definitions overlapping. (v0.9)

## Missing functionality
- [ ] Add a catch-all clause (if it does not exist) so that we don't crash during startup when a trigger is missing. (v0.9)
- [ ] Put some more effort into the coordinator to make it work well (v0.9)
- [ ] Get it working on AtomVM (v0.9)
- [ ] Add an effect that can address the white leds in led strips (v0.9) 
- [ ] Add Perlin noise functions (see: https://hackaday.com/2019/12/28/led-flame-illuminates-the-beauty-of-noise/, https://hexdocs.pm/perlin/Perlin.html) (v0.9)
- [ ] Clustering (v0.9)
  - [ ] Rethink the clustering and check whether the new livebook API endpoints might make it easier to cluster. Currently it seems to be quite complicated.
  - [ ] Provide examples on how to cluster
  - [ ] Add an example where several nodes are connected to transfer pubsub messages accross nodes
  - [ ] Implement music beat through clustering
- [ ] setting up livebook (a really working version) on windows is anything than easy :-( Can we do something about it? Investigate (v0.10)
- [ ] Create smartcells? (v1.x)

### License

### Security
- [ ] Investigate whether the creation of atoms in events can be avoided, example in trigger_names? (v0.9)

### Increase consumption
- [ ] Create a video (once v0.8 is released)
- [ ] Publish/announce on Elixirforum (once v0.8 is released, after Goatmire 2026)
- [ ] Migrate outstanding TODOs to github (v0.9)
- [ ] Get the library into nerves-livebook (v1.0)
- [ ] Move repository to its own org (fledex as an org is already taken, but fled-ex is free and I took it) (v1.0) <-- Announce this in the next release notes that this will happen? No, the runners are just not working yet. Therefore postponed to v1.0.
- [ ] Create a github pages site for the project (v0.9) <-- maybe use the site created for Goatmire?