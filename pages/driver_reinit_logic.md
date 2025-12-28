<!--
Copyright 2024, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->
# Intro
This is just some working material to reflect on what I would like to do, how I want to impelemnt it.

The Led strip gets initalized with a set of drivers and that configuration can be updated with a new set.
Ideally we don't tear everything down, but only those parts that are really requried and we reconfigure those parts that only have minor changes.

This document is investigating the approach we want to take.

> #### Note {: .info}
> 
> The different drivers are NOT uniquely identified (and it would be a too big burden on
> the user to do so), so that we have to figure out the most appropriate update from the
> information that we have at our hands.

> #### Note {: .info}
> 
> I'm not sure whether it's really necessary to go through all those troubles to keep
> existing drivers active. Maybe it's much easier to tear everything down. Maybe we should
> KISS. The only issue is that, when we recompile a strip (when changing the
> configuration), we do have to "reconfigure" the drivers.
> Usually the drivers don't change in this scenario, so tearing everything down and
> rebuildnig it feels wrong.
> A bit of a middle ground could be that we reinit (change_config) ONLY if the number of drivers, their
> types, and their orders is exactly the same.

# driver structure
Before we look at the information available, let's look at the driver/config structure.
A driver consist always of two parts:

    1. The driver module (which is also responsible for the default configuration of the driver)
    2. The driver configuration, which specifies any of the driver settings, mainly those that are different from the default configuration. The two configurations get merged together to form the actual configuration. 

It is important to realize that additional settings can be specified at runtime that are not available during configuration time that we want to preserve as far as possible (even though this is not the main use case)

The LedStrip takes a list of those drivers. It should be noted that the driver module is not necessarily unique, but can be repeated several times. This is improtant, because it allows to use the SPI driver several times but on different SPI ports.

# Info available
The information that is at our disposal is the previous configuration and the new configuration. Thus, we should compare the two with each other. This comparison is, however not super trival. Therefore we need to look on how we can make this comparison as robust as possible to match the drivers (and their configurations) as close as possible

# Recommendation
The ideas is to sort the driver modules by name, so that we have a stable order.
As a secondary sorting criteria we can use the (merged) configuration.

# Questions
How can we make sure we compare the most important parts of a driver config first? For example, in the case of an SPI driver, it would probably be the most important compare the SPI device first before we compare all the other settings.

It turns out that the standard Elixir sorting for collection types is already doing what we are looking for (except maybe sorting the keywords in the correct order), see:
https://hexdocs.pm/elixir/1.15.7/Kernel.html#module-structural-comparison. 

Thus (as a first step) it would be as simple as doing the following:

```elixir
Enum.sort(drivers)
```

Here is a simple example that demonstrates the effect:

```elixir
iex> drivers = [
...>   {String, [a: 1, b: 2, c: "abc"]},
...>   {String, [a: 2, b: 2, c: "abc"]},
...>   {String, [a: 1, b: 3, c: "abc"]},
...>   {String, [a: 1, b: 2, c: "xyz"]},
...>   {List, [a: 1, b: 2, c: "abc"]}
...> ]
[
  {String, [a: 1, b: 2, c: "abc"]},
  {String, [a: 2, b: 2, c: "abc"]},
  {String, [a: 1, b: 3, c: "abc"]},
  {String, [a: 1, b: 2, c: "xyz"]},
  {List, [a: 1, b: 2, c: "abc"]}
]

iex(7)> Enum.sort(drivers)
[
  {List, [a: 1, b: 2, c: "abc"]},
  {String, [a: 1, b: 2, c: "abc"]},
  {String, [a: 1, b: 2, c: "xyz"]},
  {String, [a: 1, b: 3, c: "abc"]},
  {String, [a: 2, b: 2, c: "abc"]}
]
```

# Conclusion
We start with simply sorting our drivers. 

# Next step
As a next step we'll look how to then make a decision whether we need to remove an existing  driver, we need to update a driver or we have to add a new driver.

The end goal is to have the same list as the `new_drivers` and therefore we iterate over the `new_drivers` list and try to find the most appropriate driver in the `old_drivers` list.

Thus could look like the following:
```elixir
def find_usable_driver_index({module, config}, drivers, first_index) do
    # remove the part of the drivers that are not interesting
    index = drivers
        |> Enum.slice(first_index, length(drivers))
        |> Enum.find_index(module)

    # correct the found index since we had a limited search range
    case index do
        nil -> nil
        x -> x + first_index
    end
end

Enum.reduce(new_drivers, {index: 0, actions: []}, fn {{module, config}, {index: first_index, actions: actions} = acc}) ->
    case find_usable_driver_index({module, config}, old_drivers, first_index) do
    x when x >=0 -> {index: x, actions:[{:update, x, {module, config}}]}
    nil -> {index: first_index, actions: [{:new, {module, config}}]}
end)
```