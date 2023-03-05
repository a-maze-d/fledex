# Introduction
This is the initial project plan developed with my son. Since I speak German
with him, it's written in German.

# Project plan
* Was moechtest do machen: Blau blinken
* Was bedeutet das genau:
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

* Welche Funktionsbloecke haben wir?
    * Schleife (loop)
    * Farbe definieren (blau, aus (=schwarz))
    * Pause (sleep)
* Wie definieren wir eine Farbe?
    * Mit Namen (blau, kek, blue)
    * Mit Hex-Zahlen (0x0000FF)
    * Mit RGB Werten (0, 0, 255) (Werte im Interval zwischen [0, 255])
        * 255 ist maximaler Wert ==> 300 gibt einen Fehler
* Wie definiert man mehrere Lampen? (Anzahl Lampen muss bekannt sein)
    * Definiere 1 Farbe & wiederhole sie (fuer eine Anzahl an Lampen / auf alle Lampen)
    * Definiere mehrer Lampen und wiederhole sie auf alle
    * Definiere Anfangs- und Endfarbe und interpoliere dazwischen
    * Definiere Farbverlaeufe
        * Regenbogenfarben
    * Kombination die oberen Moeglichkeiten

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