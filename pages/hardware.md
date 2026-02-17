<!--
Copyright 2023, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Hardware (examples)
## Introduction
This is a short description what you need to do on hardware side and how
to connect the Raspberry Pi (RPI) with the LED strip.
The description consists of 2 parts, the first one without a level-shifter
the second one with a level shifter


> #### Caution {: .warning}
> 
> YOU MUST BE A QUALIFIED ELECTRICIAN TO CONNECT TO HIGH/DANGEROUS VOLTAGES (> 30V)
> 
> NO RESPONSIBILITY CAN BE TAKEN FOR ANY DAMAGE CAUSED BY FOLLOWING THIS GUIDE

## Hardware components (example)
* Raspberry Pi Zero W (with pin header)
* LED strip with a [WS2801 chip](https://cdn-shop.adafruit.com/datasheets/WS2801.pdf) ([e.g. this one on Amazon](https://amzn.eu/d/cPdgigY))
* 5V Power supply, powerful enough to power the LED strip (e.g. [Mean Well LPV-35-5](https://www.meanwell.com/webapp/product/search.aspx?prod=LPV-35) for a 3m strip)
* (optional) [Level shifter](https://www.ti.com/product/TXB0104?qgpn=txb0104) in a easy to use format (e.g. [the one from Adafruit](https://www.adafruit.com/product/1875))
* cables, soldering iron, plugs, ...

> #### Note {: .info}
>
> You will have to adjust your shopping list to the led strip you actually buy.
> The example given here is for an WS2801. Other led strip types are similar, but you
> have to watch out to adjust to the specs of your led strip. 
> 
> **Example:** A [WS2815](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2815-datasheet.pdf) is powered with 12V (instead of the usual 5V). Thus, you will require a different power supply and a different level shifter.
> 
> Fledex currently only supports the SPI bus, but it would be easy to write a driver for 
> other bus types.

## SPI and WS2801 
We are connecting the LED strip with the Raspberry Pi through the [SPI (Serial Peripheral Interface)](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface). The SPI has 4 logical signals, but we are only interested in 2 of them.

* Clock (SCLK)
* Master Out, Slave In (MOSI)

The [WS2801](https://cdn-shop.adafruit.com/datasheets/WS2801.pdf) uses a very simple protocol via SPI. It uses as a bus where one LED will pass on the message to the next LED, removing the first information from the message. 

The following two signals are not used:

* Chip Select (CS)
* Master In, Slave Out (MISO)

This is because we neither address every chip individually nor do the chips provide any response. The LED strip usually doesn't even expose those signals.

If you look carefully, you can find on the LED strip a DI (Data In) and DO (Data Out) pins. They indicate in which direction the signals are flowing. The same also applies to the CI (Clock In) and CO (Clock Out) pins. 

When you connect your Raspberry Pi you will have to connect the MOSI (of the RPI) to the DI (of the LED strip) and the SCLK (of the RPI) to the CI (of the LED strip).

In the following we will look at two ways to connect the LED strip to the RPI, one directly (which probably works, but is not recommended) and one with a so called level shifter.

The reason for the level shifter is that the RPI (even though it's powered with 5V) uses 3.3V for its SPI port. The LED strip is powered with 5V and expects a 5V signal. We should adjust between the two voltage levels.

The driver that you should use for the WS2801 is the [`Spi.Ws2801`](`Fledex.Driver.Impl.Spi.Ws2801`) driver. If you wire it following this description, you can use the default values, so the only thing you need to do is:

```elixir
led_strip :name, Spi.Ws2801 do
    # ... here comes you strip definitions
end
```

## SPI and WS2812 (and compatible strips)
The hardware setup for a WS2812 led strip is very similar to the WS2801. We power it also through the SPI port, but there is no need to wire the clock. The clock information is embedded within the signal itself. Every bit is encoded within 3 bits. 

* `0`: is encoded as `100`
* `1`: is encoded as `110`

To fulfill the requirements we need to run the bus at a much higher frequency.

If you are using the WS2812 and follow the wiring described here, then you can use the [`Spi.Ws2812`](`Fledex.Driver.Impl.Spi.Ws2812`) driver with the default settings. You then define your led strip as:

```elixir
led_strip :name, Spi.Ws2812 do
    # ... here comes you strip definitions
end
```

If you want to use another (but compatible) led strip, you will have to adjust the settings according to the table below:

```elixir
led_strip :name, {Spi.Ws2812, [options]} do
    # ... here comes you strip definitions
end
```
| Type   | Options              | Tested | Notes |
|:-------|:---------------------|:------:|:------|
| [WS2805](https://www.superlightingled.com/PDF/WS2805-IC-Specification.pdf) | `led_type: :rgbw1w2` |        | The extra white leds can be used either by using the `Fledex.Color.RGBW` module or through a `colorint` with `0xw2w2w1w1rrggbb` |
| [WS2811](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2811-datasheet.pdf) | `led_type: :rgb`     |        | |
| [WS2812](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2812B-datasheet.pdf) | `led_type: :grb`     |   👍   | (default) |
| [WS2813](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2813-RGBW-datasheet.pdf) | `led_type: :grbw`    |        | The extra white led can be used either by using the `Fledex.Color.RGBW` module or through a `colorint` with `0xwwrrggbb` |
| [WS2814](https://suntechlite.com/wp-content/uploads/2024/06/WS2814-IC-Datasheet_V1.4_EN.pdf) | `led_type: :grbw`    |        | (same as WS2813) |
| [WS2815](https://www.ledyilighting.com/wp-content/uploads/2025/02/WS2815-datasheet.pdf) | `led_type: :grbw`    |        | (same as WS2813) |

`Tested` means that the driver has been tested with real hardware. The other have only been implemented according to the spec. Please provide feedback if you can confirm that they actually work. 

> #### Note: {: .info}
>
> The default `:delay_us` should work for all supported strips

## Finding the pins on the RPI

It can be quite tricky to find the correct pin on the RPI. Therefore several resources are linked below. The difficult part is to figure out where pin 1 is located, everything else is then quite easy.
The below drawing tries to make it clear on how you have to look at your RPI. You look from the the top down onto the processor (black) and then you can easily find pin 1.

## Direct Connection

The direct connection (especially with short connections) will probably work, because the allowed tolerance for a HIGH signal. We will still be above the required 2V. Any signal above 2V is considered as HIGH (= binary a 1) and any signal below 0.8V is considered as LOW (= binary a 0). 

![direct connection](assets/hardware.drawio.svg "Direct connection")

## Connection via a Level Shifter
It is better to use a level shifter to properly translate between the 3.3V signals and the required 5V signals.

There are [different ways](https://electronics.stackexchange.com/questions/82104/single-transistor-level-up-shifter/82112#82112) on how to level shift. We will us the Adafruit TXB0104 Bi-Directional Level shifter. It is a bit of an overkill, because we neither need to translate in both direction, nor do we require 4 signal lines, but it's easy to work with.

You have to do the following steps:

1. Connect the higher voltage and lower voltages to HV and LV respectively. This tells the level shifter to which levels we want to translate. It's important to make sure that the lower voltage is on the LV side and the higher voltage on the HV side.
2. Connect each signal line to one of the signal pins. The 3.3V to the LV side (A1-A4) and the 5V to the corresponding pins on the HV side (B1-B4).
3. Enable the output by connecting the OE pin (output enabled) to the LV pin
4. Connect all the ground lines to the GND pin.

![Connection with Level shifter](assets/hardware-Page-2.drawio.svg)

## Additional Information
### Level Shifter:
* https://electricfiredesign.com/2021/03/12/logic-level-shifters-for-driving-led-strips/
* 
### Pin information:
* https://pinout.xyz/pinout/spi# 
* https://www.raspberrypi.com/documentation/computers/raspberry-pi.html
* https://pi4j.com/1.2/pins/model-zerow-rev1.html

### Logic Levels
* https://learn.sparkfun.com/tutorials/logic-levels/all

