<!--
Copyright 2023, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Project Plan
## Introduction
This is the initial project plan developed with my son. Since I speak German
with him, it's written in German.

## The Plan 

1. Was moechtest do machen: Blau blinken
2. Was bedeutet das genau:
    1. alle Lampen sind blau
    2. warte einen Augenblick
    3. alle Lampen sind aus
    4. warte einen Augenblick
    5. fange wieder bei 1 an
```elixir
    loop :infinite do
        lamp blue, repeat: 96
        sleep 1_000
        lamp off, repeat: 96
        sleep 1_000
    end
```

3. Welche Funktionsbloecke haben wir?
    1. Schleife (loop)
    2. Farbe definieren (blau, aus (=schwarz))
    3. Pause (sleep)
4. Wie definieren wir eine Farbe?
    1. Mit Namen (blau, kek, blue)
    2. Mit Hex-Zahlen (0x0000FF)
    3. Mit RGB Werten (0, 0, 255) (Werte im Interval zwischen [0, 255])
        1. 255 ist maximaler Wert ==> 300 gibt einen Fehler
5. Wie definiert man mehrere Lampen? (Anzahl Lampen muss bekannt sein)
    1. Definiere 1 Farbe & wiederhole sie (fuer eine Anzahl an Lampen / auf alle Lampen)
    2. Definiere mehrer Lampen und wiederhole sie auf alle
    3. Definiere Anfangs- und Endfarbe und interpoliere dazwischen
    4. Definiere Farbverlaeufe
        1. Regenbogenfarben
    5. Kombination die oberen Moeglichkeiten
6.
```elixir
    loop :infinite do
        lamp red, offset: 58
        lamp green, offset: 12
        sleep 1_000
        lamp off, offset: 58
        lamp off, offset: 12
        sleep 1_000        
    end
```

## Project Plan Review
We made a walkthrough with my son to check whether the library contains all the
element that he was looking for, i.e. we have fulfilled the project plan
(Note: in the code examples we don't include the installation of the library or
the `use Fledex`)

1. Blue blinking. The solution looks a little bit different, we don't use the
   the sleep function, but we do this by a) a divisor and b) a case statement
   switching on the two "states" when checking the remaineder of the counter by
   two.
    ```elixir
    led_count = 1
    divisor = 10
    led_strip :one, :kino do
      animation :blink_blue do
        triggers ->
        counter = triggers[:one] || 0 
        counter = trunc(counter/divisor) 
        case rem(counter, 2) do
          0 -> leds(1) |> black |> repeat(led_count)
          1 -> leds(1) |> blue |> repeat(led_count)
        end
      end
    end
    ```
2. see above. We have all the elements (even though in a slightly different form)
3. see above. We have all the elements (even though in a slightly different form)
4. To define a color we can do the following:
   ```elixir
   leds(10) |> light(:blue) |> red |> light(0x00ff00) |> light({0, 0, 255}) |> light({500, 0, 0})
   ```
   This gives us 10 leds with the first 5 being colored: blue, red, green, blue, red
   Note1: The last value is outside the range, but will automatically be capped to
   stay within the allowed range. Hence the last led will be simply red. We won't throw
   an error.
   Note2: at this point we do not have translations of the colors (that would be too much work :-)
   and the customer has started to learn Enlish and therefore it's not a problem anymore
5. Here the solutions for the different parts:
   1. Use of the repeat function within the light function (note the offset does need to be specified)
   ```elixir
   leds(10) |> light(:red, 1, 5)
   ```
   Use of the repeat function for an led sequence (the resulting sequence is shorter compared to the above example):
   ```elixir
   leds(1) |> light(:red) |> repeat(5)
   ```
   2. But the latter allows us to solve the next one too
   ```elixir
   leds(3) |> red |> green |> blue |> repeat(3)
   ```
   3. This is easily done with the gradient function
   ```elixir
   leds(10) |> gradient(:blue, :red)
   ```
   4. This is solved as the above one, but we use the rainbow function
   ```elixir
   leds(10) |> rainbow
   ```
   5. The above can be combined in a wild way:
   ```elixir
   l1 = leds(7) |> rainbow |> repeat(3)
   leds(50) |> light(l1, 5) |> light(l1, 30)
   ```
6. The offset can be defined by using the offset function as shown in 5.5

## Result
The customer has accepted the implementation and we can close down this project
plan thereby :-)