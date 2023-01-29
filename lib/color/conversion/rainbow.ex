defmodule Fledex.Color.Conversion.Rainbow do
  import Bitwise

  alias Fledex.Color.Utils

  @k255 255
  @k171 171
  @k170 170
  @k85   85

  def hsv2rgb({h,s,v}, color_correction) do
    main = {(h &&& 0x80) > 0, (h &&& 0x40) > 0, (h &&& 0x20) > 0}
    offset = h &&& 0x1F
    offset8 = offset <<< 3

    third = Utils.scale8(offset8, Kernel.trunc(256/3))
    twothird = Utils.scale8(offset8, Kernel.trunc((256*2) / 3))
    {r, g, b} = determine_rgb(main, third, twothird)
    {r, g, b} = color_correction.({r ,g ,b})
    {r, g, b} = if (s != 255) do
      case (s) do
        0 -> {255, 255, 255}
        _ ->
          desat = 255 - s
          desat = Utils.scale8_video(desat, desat)
          satscale = 255 - desat
          r = if r != 0, do: Utils.scale8( r, satscale) + 1, else: r
          g = if g != 0, do: Utils.scale8( g, satscale) + 1, else: g
          b = if b != 0, do: Utils.scale8( b, satscale) + 1, else: b

          r = r + desat
          g = g + desat
          b = b + desat
          {r, g, b}
      end
    else
      {r, g, b}
    end

    {r, g, b} = if (v != 255) do
      val = Utils.scale8_video(v, v)
      case (val) do
        0 -> {0, 0, 0}
        _ ->
          r = if  r != 0, do: Utils.scale8(r, val) + 1, else: r
          g = if  g != 0, do: Utils.scale8(g, val) + 1, else: g
          b = if  b != 0, do: Utils.scale8(b, val) + 1, else: b
          {r, g, b}
      end
    else
      {r, g, b}
    end
    {r,g,b}
  end

  defp determine_rgb({:false,:false,:false}, third, _twothird) do
    {@k255 - third, third, 0}
  end
  defp determine_rgb({:false, :false, :true}, third, _twothird) do
    {@k171, @k85 + third, 0}
  end
  defp determine_rgb({:false, :true, :false}, third, twothird) do
    {@k171 - twothird, @k170 + third, 0}
  end
  defp determine_rgb({:false, :true, :true}, third, _twothird) do
    {0, @k255 - third, third}
  end
  defp determine_rgb({:true, :false, :false}, _third, twothird) do
    {0, @k171 - twothird, @k85 + twothird}
  end
  defp determine_rgb({:true, :false, :true}, third, _twothird) do
    {third, 0, @k255 - third}
  end
  defp determine_rgb({:true, :true, :false}, third, _twothird) do
    {@k85 + third, 0, @k171 - third}
  end
  defp determine_rgb({:true, :true, :true}, third, _twothird) do
    {@k170 + third, 0, @k85 - third}
  end
end
