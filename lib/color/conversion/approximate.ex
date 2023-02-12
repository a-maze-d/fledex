defmodule Fledex.Color.Conversion.Approximate do
  use Fledex.Color.Types

  @hue_red 0
  @hue_orange 32
  @hue_yellow 64
  @hue_green 96
  @hue_aqua 128
  @hue_blue 160
  @hue_purple 192
  @hue_pink 224

  alias Fledex.Color.Utils

  @spec rgb2hsv(rgb) :: hsv
  def rgb2hsv({r,g,b}) do
    desat = find_desaturation({r,g,b})
    {r,g,b} = {r-desat, g-desat, b-desat}
    s = 255 - desat
    s = if (s != 255) do
      255 - trunc(:math.sqrt((255 - s) * 256));
    else
      s
    end
    if (r + g + b == 0) do
      {0, 0, 255-s}
    else
      {r,g,b} = scale_to_compensate({r,g,b}, s)     # for desaturation
      total = r+g+b
      {r,g,b} = scale_to_compensate({r,g,b}, total) # for small value
      v = if (total > 255) do
        255
      else
        v = qadd8(desat, total)
        if (v != 255), do: :math.sqrt(v*256), else: v
      end
      highest = Enum.max([r,g,b])
      h = case {{r,g,b}, highest} do
        {{r, 0, _b}, r} ->
          ((@hue_purple + @hue_pink) / 2) + Utils.scale8( qsub8(r, 128), fixfrac8(48,128))
        {{r,g,_b}, r} when (r - g) > g ->
          @hue_red + Utils.scale8( g, fixfrac8(32,85))
        {{r,g,_b}, r} ->
          @hue_orange + Utils.scale8( qsub8((g - 85) + (171 - r), 4), fixfrac8(32,85));
        {{r,g,0}, g} ->
          @hue_yellow + ((Utils.scale8( qsub8(171,r), 47) + Utils.scale8( qsub8(g,171), 96))/2)
        {{_r,g,b}, g} when (g-b) > b ->
          @hue_green + Utils.scale8( b, fixfrac8(32,85))
        {{_r,g,b}, g} ->
          @hue_aqua + Utils.scale8( qsub8(b, 85), fixfrac8(8,42))
        {{0,_g,b}, b} ->
          @hue_aqua + ((@hue_blue - @hue_aqua) / 4) + Utils.scale8( qsub8(b, 128), fixfrac8(24,128))
        {{r,_g,b}, b} when (b-r) > r ->
          @hue_blue + Utils.scale8( r, fixfrac8(32,85))
        {{r,_g,b}, b} ->
          @hue_purple + Utils.scale8( qsub8(r, 85), fixfrac8(32,85))
      end
      {h+1, s, v}
    end
  end

  defp fixfrac8(n,d) do
    trunc((n*256)/(d))
  end

  @spec scale_to_compensate(rgb, byte) :: rgb
  defp scale_to_compensate({r,g,b}, s) when s < 255 do
    s = if s == 0, do: 1, else: s
    scaleup = 655535 / (s)
    r = trunc(r*scaleup/256)
    g = trunc(g*scaleup/256)
    b = trunc(b*scaleup/256)
    {r,g,b}
  end
  defp scale_to_compensate({r,g,b}, _s), do: {r,g,b}

  @spec find_desaturation(rgb) :: byte
  defp find_desaturation({r,g,b}) do
    #     // find desaturation
    #     uint8_t desat = 255;
    #     if( r < desat) desat = r;
    #     if( g < desat) desat = g;
    #     if( b < desat) desat = b;
    255
      |> adj_desat(r)
      |> adj_desat(g)
      |> adj_desat(b)
  end

  @spec adj_desat(byte, byte) :: byte
  defp adj_desat(desat, value)
  defp adj_desat(desat, value) when value < desat, do: value
  defp adj_desat(desat, _value), do: desat

  @spec qadd8(byte, byte) :: byte
  defp qadd8(i,j) when i+j>255, do: 255
  defp qadd8(i, j) do
    i + j
  end

  @spec qsub8(byte, byte) :: byte
  defp qsub8(i,j) when i-j<0, do: 0
  defp qsub8(i,j) do
    i - j
  end
end
