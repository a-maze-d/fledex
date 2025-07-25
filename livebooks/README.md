<!--
Copyright 2023, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Intro
This is a description of the livebooks in this folder. The examples are structured in such a way that we slowly walk up the abstraction stack. From very low level to a high level language. If are not interested in the technical details, the motivations, and the decisions then you probably want to only look at livebook "[#1 First steps with an led strip](livebooks/README.md#1-first-steps-with-an-led-strip)" (which has nothing to do with Fledex as such but how to set up your LED strip correctly) and the dsl specific chapters starting with livebook [#6 Fledex DSL](livebooks/README.md#6-fledex-dsl) (to define your animations). Only the whole set will give you, however, a good overview.

It is recommended that when you look at the different livebooks you look at the [Architecture Overview](../docs/architecture.md) in parallel. Take also a look at the [Hardware](../docs/hardware.md) description, because you need to have your hardware setup ready to run anything on a real led strip. Most examples can be run in the livebook and don't require any additional hardware.

The different livebooks have been categorized:

* **intro:** You probably want to start with this one
* **background:** You can skip this livebook, except if you want to understand the evolution of the library
* **details:** You should probably look at those livebooks, because it explains some details and generic concepts. You can do so either right from the beginning, or at a later point in time (when you feel that it's time to learn more about it)
* **usage:** Those livebooks you really should look at to learn how to use the library

# 1. First steps with an LED strip (intro)
[Link](1_first_steps_with_an_led_strip.livemd)

The first livebook has nothing to do with the Fledex library, but describes on how to set up the [RaspberryPi](https://www.raspberrypi.org/), how to connect the LED strip to it and how we can communicate with it via the SPI bus. It also shows how easy it is to communicate to an LED strip. At the same time it is cumbersome, due the sheer number of LEDs that can be addressed. This example is good to

- ensure that everything is set up correctly (before we bring the complexity of a library in)
- get an understanding on why Fledex was created in the first place to make the definition of the strip easier

We don't really want to work on this level

# 2. Fledex: First steps (background)
[Link](2_fledex_first_steps.livemd)

The first steps with the Fledex library. The example shows how the LED strip can be emulated with the Kino driver, but it does contain commented out code for the SPI driver too to send it to a real LED strip.
In the driver configs we define an error correction, since the 5050 chips have too intensive green and blue LEDs that need to be compensated to have a more natural look. The Kino driver does not require such a compensation, even though it is possible to define one too.
By changing the definition of our LEDs we can also create some simple animations

This example works still on a very low level, one that we do not want use. 

# 2b. Fledex: How to define LEDs (details)
[Link](2b_fledex_how_to_define_leds.livemd)

In this livebook we take a closer look how we can define sequences of leds. We start with a brief look at how we can define colors, but we'll take a more detailed look at colors in __3b. Fledex: More about colors__. Then we'll look at sub-sequences and how to generate sequences with functions.

# 3. Fledex: Animations (background)
[Link](3_fledex_animations.livemd)

In this livebook we look how animations can be defined, this is the next step(s) above the `Fledex.LedStrip`. The `Fledex.Animation.Manager` is the level that we want to operate on and the following examples will use what we have explored here and will create some concrete examples:

* a clock (using local information) and 
* a weather indicator (collecting data via the internet)

# 3b. Fledex: More about colors (details)
[Link](3b_fledex_everything_about_colors.livemd)

Here we talk a bit more about colors and even color corrections

# 4. Fledex: Clock example (background)
[LInk](4_fledex_clock_example.livemd)

This is the first "meaningful" example that displays the current time on the LED strip. We define 4 "animations" for:

* the indicators (otherwise it becomes hard to read the time), 
* the seconds (red), 
* the minutes (green), and 
* the hours (blue).

This example demonstrates how easy we do things when we can pull the information whenever needed. The current time is something that is readily available on the device and can be called as often as we want. Hence we can call this function every time we paint the strip.

**CAUTION:** we repaint the LED strip very frequent and therefore it's nothing you want to do with data that is expensive to retrieve.

# 5. Fledex: Weather example (background)
[Link](5_fledex_weather_example.livemd)

This is an example where we **CANNOT** fetch the information every time we want to paint the strip (which could be serveral times per second), since we are calling a public API. The API would surely block us if we would try to attempt to call it that often.

Therefore we fetch the information at regular intervals, outside of our animation loop. For that we define a small GenServer which makes the API call, and publishes the data via pubsub to then be picked up by the animation loop.

# 6. Fledex: DSL (usage)
[Link](6_fledex_dsl.livemd)

In this example we will look at the Fledex DSL that removes a lot of the boilerplate and therefore makes the definition of an LED strip even easier. Under the hood it uses the same principles as the ones we have encountered in the examples 3-5.

In this example we will reimplement the Clock, but this time with our DSL.

# 7. Fledex: Effects (usage)
[Link](7_fledex_effects.livemd)

In this chapter we take a look at the effect functionality. An animation can be "spiced" with one or more effects. This id also part of the Fledex DSL.

We won't look at all possible effects, but at some examples. It is quite easy to create your own effect and we'll take a look on how to do that too.

# 8. Fledex: Component (usage)
[Link](8_fledex_component.livemd)

In this chapter we will take a look on how to create reusable components. This way you don't have to redefine certain animations

# 9. Fledex: Job (usage)
[Link](9_fledex_jobs.livemd)

Animations often require some time activity. In this chapter we will take a look at the `job` feature that makes the scheduling of repetitive tasks much easier by providing a cron-job like feature. This is mainly intended to trigger some events for the animation(s), but could really be used for anything.

# 10. Fledex: Coordinator (usage)
# School livebooks
A couple of livebooks are intended for school project

## Schule: Hardware Erklärung (in German)
[Link](school/hardware_erklaerung.livemd)

This describes in a very easy way how the data gets transfered on the SPI bus from the Raspberry Pi to the Leds.

## Schule: Licht und Farben (in German)
[Link](school/licht_und_farben.livemd)

This explains in a simple way
* what light is
* how we perceive light
* and how we see mixed colors.

It also allows the kids to play around and mix colors