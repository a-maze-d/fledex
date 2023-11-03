This is a description of the livebooks in this folder.

# First steps
This small livebook is to go through the first steps of talking with LED strip via the SPI bus.
It is quite simple and straight forward if everything is wired correctly.

# 1. First steps with an led strip
The first livebook has nothing to do wiht the fledex library, but describes on how to set up the raspberry pi, how to connect the led strip to it and how we can communicate with it via the SPI bus. It also shows how cumbersome it is to define anything on the strip. This example is good to

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

This example works on a very low level, one that we still do not want to work with 

# 3. Fledex: Animations
In this livebook we look how animations can be defined, this is the next step(s) above the `LedsDriver`. The `LedAnimationManager` is the level that we want to operate on and the following examples will use what we have explored here and will create some concrete examples, a clock (using local information) and a weather indicator (collecting data via the internet)

# 4. Fledex: Clock example
This is the first "meaningful" example that displays the current time on the ledstrip. We define 4 "animations" for the indicators (otherwise it becomes hard to read the time), the seconds (red), the minutes (green) and the hours (blue).
This example demonstrates how we can pull the information whenever needed. The current time is something that is readily available and we can call this function as often as we want. Hence we can call this function every time we paint the strip.

# 5. Fledex: Weather example
This is an example where we CANNOT fetch the information every time we want to paint the strip (which could be serveral times per second), since we are calling a public API. The API would surely block us if we would try to attempt to call it that often.

Therefore we fetch the information at regular intervals, outside of our animation loop. For that we define a small GenServer which makes the API call, and publishes the data via pubsub to then be picked up by the animation loop.

# 6. Fledex: DSL
In this example we will look at the Fledex DSL that removes a lot of the boilerplate and therefore makes the definition of an LED strip even easier. Under the hood it's the same as the examples 3-5.