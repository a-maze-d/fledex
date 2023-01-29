defmodule Fledex.Color.Conversion.Spectrum do
  @hsv_section_3 0x40
  alias Fledex.Utils

  def hsv2rgb({h, s, v}, _extra_color_correction) do
    #     CHSV hsv2(hsv);
    # hsv2.hue = scale8( hsv2.hue, 191);
    # hsv2rgb_raw(hsv2, rgb);
      h = Utils.scale8(h, 191)

#     void hsv2rgb_raw_C (const struct CHSV & hsv, struct CRGB & rgb)
# {
#     // Convert hue, saturation and brightness ( HSV/HSB ) to RGB
#     // "Dimming" is used on saturation and brightness to make
#     // the output more visually linear.

#     // Apply dimming curves
#     uint8_t value = APPLY_DIMMING( hsv.val);
#     uint8_t saturation = hsv.sat;

#     // The brightness floor is minimum number that all of
#     // R, G, and B will be set to.
#     uint8_t invsat = APPLY_DIMMING( 255 - saturation);
#     uint8_t brightness_floor = (value * invsat) / 256;
invsat = 255 - s
brightness_floor = Kernel.trunc((v*invsat) / 256)

#     // The color amplitude is the maximum amount of R, G, and B
#     // that will be added on top of the brightness_floor to
#     // create the specific hue desired.
#     uint8_t color_amplitude = value - brightness_floor;
color_amplitude = v - brightness_floor

#     // Figure out which section of the hue wheel we're in,
#     // and how far offset we are withing that section
#     uint8_t section = hsv.hue / HSV_SECTION_3; // 0..2
#     uint8_t offset = hsv.hue % HSV_SECTION_3;  // 0..63
section = trunc(h / @hsv_section_3)
offset = rem(h, @hsv_section_3)

#     uint8_t rampup = offset; // 0..63
#     uint8_t rampdown = (HSV_SECTION_3 - 1) - offset; // 63..0
rampup = offset
rampdown = (@hsv_section_3 - 1) - offset

#     // We now scale rampup and rampdown to a 0-255 range -- at least
#     // in theory, but here's where architecture-specific decsions
#     // come in to play:
#     // To scale them up to 0-255, we'd want to multiply by 4.
#     // But in the very next step, we multiply the ramps by other
#     // values and then divide the resulting product by 256.
#     // So which is faster?
#     //   ((ramp * 4) * othervalue) / 256
#     // or
#     //   ((ramp    ) * othervalue) /  64
#     // It depends on your processor architecture.
#     // On 8-bit AVR, the "/ 256" is just a one-cycle register move,
#     // but the "/ 64" might be a multicycle shift process. So on AVR
#     // it's faster do multiply the ramp values by four, and then
#     // divide by 256.
#     // On ARM, the "/ 256" and "/ 64" are one cycle each, so it's
#     // faster to NOT multiply the ramp values by four, and just to
#     // divide the resulting product by 64 (instead of 256).
#     // Moral of the story: trust your profiler, not your insticts.

#     // Since there's an AVR assembly version elsewhere, we'll
#     // assume what we're on an architecture where any number of
#     // bit shifts has roughly the same cost, and we'll remove the
#     // redundant math at the source level:

#     //  // scale up to 255 range
#     //  //rampup *= 4; // 0..252
#     //  //rampdown *= 4; // 0..252

#     // compute color-amplitude-scaled-down versions of rampup and rampdown
#     uint8_t rampup_amp_adj   = (rampup   * color_amplitude) / (256 / 4);
#     uint8_t rampdown_amp_adj = (rampdown * color_amplitude) / (256 / 4);
rampup_amp_adj = (rampup * color_amplitude) / (256/4)
rampdown_amp_adj = (rampdown * color_amplitude) / (256/4)

#     // add brightness_floor offset to everything
#     uint8_t rampup_adj_with_floor   = rampup_amp_adj   + brightness_floor;
#     uint8_t rampdown_adj_with_floor = rampdown_amp_adj + brightness_floor;
rampup_adj_with_floor = rampup_amp_adj + brightness_floor
rampdown_adj_with_floor = rampdown_amp_adj + brightness_floor

set_colors(section, brightness_floor, rampup_adj_with_floor, rampdown_adj_with_floor)
#     if( section ) {
#         if( section == 1) {
#             // section 1: 0x40..0x7F
#             rgb.r = brightness_floor;
#             rgb.g = rampdown_adj_with_floor;
#             rgb.b = rampup_adj_with_floor;
#         } else {
#             // section 2; 0x80..0xBF
#             rgb.r = rampup_adj_with_floor;
#             rgb.g = brightness_floor;
#             rgb.b = rampdown_adj_with_floor;
#         }
#     } else {
#         // section 0: 0x00..0x3F
#         rgb.r = rampdown_adj_with_floor;
#         rgb.g = rampup_adj_with_floor;
#         rgb.b = brightness_floor;
#     }
# }

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
