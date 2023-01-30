defmodule Fledex.Color.Conversion.Raw do
  @hsv_section_3 0x40

  def hsv2rgb({h,s,v}, _color_correction) do
    invsat = 255 - s
    brightness_floor = Kernel.trunc((v*invsat) / 256)

    color_amplitude = v - brightness_floor

    section = trunc(h / @hsv_section_3)
    offset = rem(h, @hsv_section_3)

    rampup = offset
    rampdown = (@hsv_section_3 - 1) - offset

    rampup_amp_adj = (rampup * color_amplitude) / (256/4)
    rampdown_amp_adj = (rampdown * color_amplitude) / (256/4)

    rampup_adj_with_floor = rampup_amp_adj + brightness_floor
    rampdown_adj_with_floor = rampdown_amp_adj + brightness_floor

    set_colors(section, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor)
  end

  def set_colors(section, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor)
  def set_colors(0, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor) do
    {rampdown_adj_with_floor, rampup_adj_with_floor, brightness_floor}
  end
  def set_colors(1, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor) do
    {brightness_floor, rampdown_adj_with_floor, rampup_adj_with_floor}
  end
  def set_colors(_, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor) do
    {rampup_adj_with_floor, brightness_floor, rampdown_adj_with_floor}
  end
end
