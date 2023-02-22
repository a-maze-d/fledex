```elixir
Mix.install([
  {:circuits_spi, "~> 1.3"}
])
```

Den SPI Bus suchen und oeffnen
==============================

Als erstes versuchen wir herauszufinden was es fuer SPI Busse es gibt.
```elixir
_ = Circuits.SPI.bus_names()
```

Als naechsten Schritt machen wir den ersten SPI Bus auf und wieder zu und schauen ob irgend ein Fehler dabei auftritt. Wir vergleichen immer den Rueckgabewert der Funktionen mit dem Wert den wir erwarten

```elixir
{:ok, ref} =
  Circuits.SPI.open("spidev0.0",
    mode: 0,
    bits_per_word: 8,
    speed_hz: 1_000_000,
    delay_us: 10,
    lsb_first: false
  )

:ok = Circuits.SPI.close(ref)
```

Die Daten Struktur definieren
=============================
Als naechstes definieren wir die richtige Datenstruktur. Es ist eine binaere Stuktur mit den Farben RGB mit je 1 byte (8 bit, 256 Werten). Jede LED hat solch eine Struktur und die werden einfach hintereinander gehaengt. Wir erledigen das hier beispielhaft an 3 LEDs. Wir definieren unseren (LED-)Range und akkumulieren die Daten.

```elixir
range = Enum.to_list(1..3)

data =
  Enum.reduce(range, <<>>, fn _index, leds ->
    leds <> <<0xFF, 0x00, 0x00>>
  end)
```

Wir senden die Daten an die Lichterkette
========================================
Zuerst

    Oeffnen wir den SPI Bus
    Dann definieren wir die Datenstruktur (nur fuer 3 LEDs, so wie im letzten Beispiel)
    Dann schicken wir die Daten auf den SPI Bus
    Dan machen wir den SPI Bus wieder zu.

Mal schauen was das Ergebnis sein wird

```elixir
defmodule HsvToRgb do
  # we define a couple of color helpers taken from 
  # https://github.com/supersimple/chameleon/blob/main/lib/chameleon/hsl.ex
  def to_rgb(hsl) do
      c = (1 - :erlang.abs(2 * (hsl.l / 100) - 1)) * (hsl.s / 100)
      x = c * (1 - :erlang.abs(remainder(hsl.h) - 1))
      m = hsl.l / 100 - c / 2
      [r, g, b] = calculate_rgb(c, x, hsl.h)

      %{
        r: round((r + m) * 255), 
        g: round((g + m) * 255), 
        b: round((b + m) * 255)
      }
    end

  defp remainder(h) do
    a = h / 60.0
    :math.fmod(a, 2)
  end

  defp calculate_rgb(c, x, h) when h < 60, do: [c, x, 0]
  defp calculate_rgb(c, x, h) when h < 120, do: [x, c, 0]
  defp calculate_rgb(c, x, h) when h < 180, do: [0, c, x]
  defp calculate_rgb(c, x, h) when h < 240, do: [0, x, c]
  defp calculate_rgb(c, x, h) when h < 300, do: [x, 0, c]
  defp calculate_rgb(c, x, _h), do: [c, 0, x]
end

test_data = %{
  h: 90, 
  s: 100, 
  l: 50 
}
result = HsvToRgb.to_rgb(test_data)
```

```elixir
# 1
{:ok, ref} =
  Circuits.SPI.open("spidev0.0",
    mode: 0,
    bits_per_word: 8,
    speed_hz: 1_000_000,
    delay_us: 10,
    lsb_first: false
  )

# 2
led_range = Enum.to_list(1..96)
timing_range = Enum.to_list(1..10_000)

# Enum.each(timing_range, fn (tindex) ->  
#   # farbe = "FFFFFF"
#   # String.split(farbe)
#   data =
#     Enum.reduce(led_range, <<>>, fn (lindex, leds) ->
#       hsl = %{l: 4*lindex, s: 100, l: 50 }
#       result = HsvToRgb.to_rgb(test_data)
#       leds <> <<result.r, result.g, result.b>>
#       # leds <> <<rem(128*tindex*lindex, 256), 0, 0>>
#     end)
#   # data = <<0xFF, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0x00>>
#   # 3
#   {:ok, _} = Circuits.SPI.transfer(ref, data)
#   Process.sleep(1)
# end)
data =
  Enum.reduce(led_range, <<>>, fn lindex, leds ->
    leds <> <<0, 0, 0>>
  end)

{:ok, _} = Circuits.SPI.transfer(ref, data)
# 4
:ok = Circuits.SPI.close(ref)
```