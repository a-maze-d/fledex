<!--
Copyright 2023, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
This document describes the dsl (domain specific language) that I'm trying to create

# Ingredients
We have several ingredients that control different aspects:
1. `led_strip` enclosure defines a new led_strip. This should spin up a LedDriver instance. If this is not specified, a default should be assumed
2. `animation` enclosure defines a single animate-able led sequence within an `led_strip`

# Configuration
Both parts need to be configurable through some simple `with` statements. Here some potential examples
```
animation
    with loop_delay: 1_000,
    with animation_function: &move_one_left/1,
    with triggers: [:timer, :counter]
    with color_correction: ...
do
    ### some led pattern ###
    ### maybe with some delays and pattern modifications ###
end
```
This could be achieved by having a [Keyword](https://hexdocs.pm/elixir/Keyword.html) list and the "with" converting to tuples of the form `{atom, value}`

# Triggers and Events
It should be easy to create events (like animation reached end of strip) and easy to consume them

# Temporary state
It shoudl be easy to store some temporary state in the loop (what was my value last time)
