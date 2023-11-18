# Intro
This is a description of the livebooks in this folder. The examples are structured in such a way that we slowly walk up the abstraction stack. From very low level to a high level language. If are not interested in the technical details, the motivations, and the decisions then you probably want to only look livebook [#1](livebooks/README.md#1-first-steps-with-an-led-strip) (to set up your LED strip correctly) and [#6](livebooks/README.md#6-fledex-dsl) (to define your animations). Only the whole set will give you, however, a good overview.

It is recommended that you look at the different livebooks in parallel to the [Architecture Overview](../docs/architecture.md).

# 1. First steps with an LED strip
The first livebook has nothing to do with the Fledex library, but describes on how to set up the [RaspberryPi](https://www.raspberrypi.org/), how to connect the LED strip to it and how we can communicate with it via the SPI bus. It also shows how easy it is to communicate to an LED strip. At the same time it is cumbersome, due the sheer number of LEDs that can be addressed. This example is good to

- ensure that everything everything is set up correctly (before we bring the complexity of a library in)
- get an understanding on why Fledex was created in the first place to make the definition of the strip easier

We don't really want to work on this level

# 2. Fledex: First steps
The first steps with the Fledex library. The example shows how the LED strip can be emulated with
the Kino driver, but it does contain commented out code for the SPI driver too to send it to a
real LED strip.
In the driver configs we define an error correction, since the 5050 chips have too intensive green
and blue LEDs that need to be compensated to have a more natural look. The Kino driver does not
require such a compensation, even though it is possible to define one too.
By changing the definition of our LEDs we can also create some simple animations

This example works still on a very low level, one that we do not want use. 

# 3. Fledex: Animations
In this livebook we look how animations can be defined, this is the next step(s) above the `LedsDriver`. The `LedAnimationManager` is the level that we want to operate on and the following examples will use what we have explored here and will create some concrete examples:

* a clock (using local information) and 
* a weather indicator (collecting data via the internet)

# 4. Fledex: Clock example
This is the first "meaningful" example that displays the current time on the LED strip. We define 4 "animations" for:

* the indicators (otherwise it becomes hard to read the time), 
* the seconds (red), 
* the minutes (green), and 
* the hours (blue).

This example demonstrates how easy we do things when we can pull the information whenever needed. The current time is something that is readily available on the device and can be called as often as we want. Hence we can call this function every time we paint the strip.

**CAUTION:** we repaint the LED strip very frequent and therefore it's nothing you want to do with data that is expensive to retrieve.

# 5. FLEDex: Weather example
This is an example where we **CANNOT** fetch the information every time we want to paint the strip (which could be serveral times per second), since we are calling a public API. The API would surely block us if we would try to attempt to call it that often.

Therefore we fetch the information at regular intervals, outside of our animation loop. For that we define a small GenServer which makes the API call, and publishes the data via pubsub to then be picked up by the animation loop.

# 6. Fledex: DSL
In this example we will look at the Fledex DSL that removes a lot of the boilerplate and therefore makes the definition of an LED strip even easier. Under the hood it uses the same principles as the ones we have encountered in the examples 3-5.

In this example we will reimplement the Clock, but this time with our DSL.