This is a description of the livebooks in this folder.

# First steps
This small livebook is to go through the first steps of talking with LED strip via the SPI bus.
It is quite simple and straight forward if everything is wired correctly.

# Fledex
The first steps with the Fledex library. The example shows how the LED strip can be emulated with
the Kino driver, but it does contain commented out code for the SPI driver too to send it to a
real LED strip.
In the driver configs we define an error correction, since the 5050 chips have too intensive green
and blue LEDs that need to be compensated to have a more natural look. The Kino driver does not
require such a compensation, even though it is possible to define one too.

