defmodule Fledex.Color.Conversion.Rainbow do
  import Bitwise
  alias Fledex.Utils

  @k255 255
  @k171 171
  @k170 170
  @k85   85

  def hsv2rgb({h,s,v}, extra_color_correction) do
    determine_rgb(h)
      |> extra_color_correction.()
      |> desaturate(s)
      |> scale_luminance(v)
  end

  defp determine_rgb(h) do
    main = {(h &&& 0x80) > 0, (h &&& 0x40) > 0, (h &&& 0x20) > 0}
    offset = h &&& 0x1F
    offset8 = offset <<< 3

    third = Utils.scale8(offset8, Kernel.trunc(256/3))
    twothird = Utils.scale8(offset8, Kernel.trunc((256*2) / 3))
    determine_rgb(main, third, twothird)
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

  defp desaturate({r, g, b}, 255), do: {r, g, b}
  defp desaturate(_, 0), do: {255, 255, 255}
  defp desaturate({r,g,b}, s) do
    desat = 255 - s
    desat = Utils.scale8(desat, desat) + 1
    satscale = 255 - desat
    r = if r != 0, do: Utils.scale8(r, satscale) + 1, else: r
    g = if g != 0, do: Utils.scale8(g, satscale) + 1, else: g
    b = if b != 0, do: Utils.scale8(b, satscale) + 1, else: b

    r = r + desat
    g = g + desat
    b = b + desat
    {r, g, b}
  end

  defp scale_luminance(rgb, 255), do: rgb
  defp scale_luminance(_, v) when ((v*v) >>> 8) == 0, do: {0, 0, 0}
  defp scale_luminance({r,g,b}, v) do
    val = Utils.scale8(v, v) + 1
    r = if  r != 0, do: Utils.scale8(r, val) + 1, else: r
    g = if  g != 0, do: Utils.scale8(g, val) + 1, else: g
    b = if  b != 0, do: Utils.scale8(b, val) + 1, else: b
    {r, g, b}
  end

end
