<!--
Copyright 2023-2024, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# animation, static, component
The animation macro should return a tuple with at least

* animation name (`:atom`)
* animation configuration (`Animator.config_t()` structure)

# effect
The effect injects itself into the animation(s). We want it to be
able to operate with several animations at the same time, i.e. something like this
```elixir
use Fledex
effect Fledex.Effect.Rotation do
    animation :joe do
     leds(20)
    end
    animation :mary do
        leds(10)
    end
end
```
Therefore the effects should return a list of animation config structures (see above)
We want to also be able to stack effects which means that something like this should
also be possible:
```elixir
use Fledex
effect Fledex.Effect.Rotation do
    animation :joe do
        leds(20)
    end
    effect Fledex.Effect.Dimming do
        animation :mary do
            leds(10)
        end
    end
end
``` 
Because of that, it would make sense if an animation would return
also a list of animation configs

# led strip
The `led_strip` takes a list of config structs and creates the led strip configuration

# jobs & coordinators
It should also be possible to configure jobs and coordinators (on root level), i.e.:
``` elixir
use Fledex
led_strip :john, :none do
    animation :joe, do
        leds(10)
    end

    job :joe_job, "* * * * * *", do
        :ok
    end

    coordinator :coord do
        # we don't know yet how a coordinator will be configured
    end
end
```
Coordinators and jobs will also return a configuration, but of type `:job` and `:coordinator`.

# Conclusion

1. An animation consists of an config struct (see above for details)
2. `animation`, `static`, `component` all return a list of animation structs
3. `effect` takes in a list of animation struts and returns a list of animation structs
