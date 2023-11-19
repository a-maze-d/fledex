defmodule Fledex.Color.Types do
    @type rgb :: {red :: 0..255, green :: 0..255, blue :: 0..255}
    @type hsv :: {hue :: 0..255, saturation :: 0..255, value :: 0..255}
    @type hsl :: {hue :: 0..255, saturation :: 0..255, light :: 0..255}
    @type colorint :: 0..0xFFFFFF
end
