defmodule Fledex.Pixeltypes.Hsv do
  import Bitwise

  alias Fledex.Lib8tion.Scale8
  alias Fledex.Pixeltypes.Rgb

  @k255 255
  @k171 171
  @k170 170
  @k85   85

  defstruct h: 0, s: 0, v: 0

  def to_rgb(hsv) do
    hsv2rgb_rainbow(hsv)
  end

  def color_correction_g2({r, g, b}) do
    {r, g >>> 2, b}
  end
  def color_correction_none({r,g,b}) do
      {r, g, b}
  end

  defp hsv2rgb_rainbow(hsv, color_correction \\ &color_correction_none/1) do
    # This is a reimplementation of the fastled algorithm
    # (reducing the ifdefs)
#     void hsv2rgb_rainbow( const CHSV& hsv, CRGB& rgb)
# {
#     // Yellow has a higher inherent brightness than
#     // any other color; 'pure' yellow is perceived to
#     // be 93% as bright as white.  In order to make
#     // yellow appear the correct relative brightness,
#     // it has to be rendered brighter than all other
#     // colors.
#     // Level Y1 is a moderate boost, the default.
#     // Level Y2 is a strong boost.
#     const uint8_t Y1 = 1;
#     const uint8_t Y2 = 0;

#     // G2: Whether to divide all greens by two.
#     // Depends GREATLY on your particular LEDs
#     const uint8_t G2 = 0;

#     // Gscale: what to scale green down by.
#     // Depends GREATLY on your particular LEDs
#     const uint8_t Gscale = 0;


#     uint8_t hue = hsv.hue;
#     uint8_t sat = hsv.sat;
#     uint8_t val = hsv.val;

#     uint8_t offset = hue & 0x1F; // 0..31

#     // offset8 = offset * 8
#     uint8_t offset8 = offset;
#     {
#         // On ARM and other non-AVR platforms, we just shift 3.
#         offset8 <<= 3;
#     }
main = {(hsv.h &&& 0x80) > 0, (hsv.h &&& 0x40) > 0, (hsv.h &&& 0x20) > 0}
offset = hsv.h &&& 0x1F
offset8 = offset <<< 3

#     uint8_t third = scale8( offset8, (256 / 3)); // max = 85
third = Scale8.scale8(offset8, Kernel.trunc(256/3))
twothird = Scale8.scale8(offset8, Kernel.trunc((256*2) / 3))
#     uint8_t r, g, b;
{r, g, b} = determine_rgb(main, third, twothird)
{r, g, b} = color_correction.({r ,g ,b})

#     // This is one of the good places to scale the green down,
#     // although the client can scale green down as well.
#     if( G2 ) g = g >> 1;
#     if( Gscale ) g = scale8_video_LEAVING_R1_DIRTY( g, Gscale);

#     // Scale down colors if we're desaturated at all
#     // and add the brightness_floor to r, g, and b.
{r, g, b} = if (hsv.s != 255) do
  case (hsv.s) do
    0 -> {255, 255, 255}
    _ ->
      desat = 255 - hsv.s
      desat = Scale8.scale8_video(desat, desat)
      satscale = 255 - desat
      r = if r != 0, do: Scale8.scale8( r, satscale) + 1, else: r
      g = if g != 0, do: Scale8.scale8( g, satscale) + 1, else: g
      b = if b != 0, do: Scale8.scale8( b, satscale) + 1, else: b

      r = r + desat
      g = g + desat
      b = b + desat
      {r, g, b}
  end
else
  {r, g, b}
end
#     if( sat != 255 ) {
#         if( sat == 0) {
#             r = 255; b = 255; g = 255;
#         } else {
#             uint8_t desat = 255 - sat;
#             desat = scale8_video( desat, desat);

#             uint8_t satscale = 255 - desat;
#             //satscale = sat; // uncomment to revert to pre-2021 saturation behavior

#             //nscale8x3_video( r, g, b, sat);
# #if (FASTLED_SCALE8_FIXED==1)
#             r = scale8_LEAVING_R1_DIRTY( r, satscale);
#             g = scale8_LEAVING_R1_DIRTY( g, satscale);
#             b = scale8_LEAVING_R1_DIRTY( b, satscale);
#             cleanup_R1();
# #else
#             if( r ) r = scale8( r, satscale) + 1;
#             if( g ) g = scale8( g, satscale) + 1;
#             if( b ) b = scale8( b, satscale) + 1;
# #endif
#             uint8_t brightness_floor = desat;
#             r += brightness_floor;
#             g += brightness_floor;
#             b += brightness_floor;
#         }
#     }

  {r, g, b} = if (hsv.v != 255) do
    val = Scale8.scale8_video(hsv.v, hsv.v)
    case (val) do
      0 -> {0, 0, 0}
      _ ->
        r = if  r != 0, do: Scale8.scale8(r, val) + 1, else: r
        g = if  g != 0, do: Scale8.scale8(g, val) + 1, else: g
        b = if  b != 0, do: Scale8.scale8(b, val) + 1, else: b
        {r, g, b}
    end
  else
    {r, g, b}
  end
  #     // Now scale everything down if we're at value < 255.
#     if( val != 255 ) {

#         val = scale8_video_LEAVING_R1_DIRTY( val, val);
#         if( val == 0 ) {
#             r=0; g=0; b=0;
#         } else {
#             // nscale8x3_video( r, g, b, val);
# #if (FASTLED_SCALE8_FIXED==1)
#             r = scale8_LEAVING_R1_DIRTY( r, val);
#             g = scale8_LEAVING_R1_DIRTY( g, val);
#             b = scale8_LEAVING_R1_DIRTY( b, val);
#             cleanup_R1();
# #else
#             if( r ) r = scale8( r, val) + 1;
#             if( g ) g = scale8( g, val) + 1;
#             if( b ) b = scale8( b, val) + 1;
# #endif
#         }
#     }

#     // Here we have the old AVR "missing std X+n" problem again
#     // It turns out that fixing it winds up costing more than
#     // not fixing it.
#     // To paraphrase Dr Bronner, profile! profile! profile!
#     //asm volatile(  ""  :  :  : "r26", "r27" );
#     //asm volatile (" movw r30, r26 \n" : : : "r30", "r31");
#     rgb.r = r;
#     rgb.g = g;
#     rgb.b = b;
# }
    %Rgb{r: r, g: g, b: b}
  end

  #     if( ! (hue & 0x80) ) {
  #         // 0XX
  #         if( ! (hue & 0x40) ) {
  #             // 00X
  #             //section 0-1
  #             if( ! (hue & 0x20) ) {
  #                 // 000
  #                 //case 0: // R -> O
  #                 r = K255 - third;
  #                 g = third;
  #                 b = 0;
  #                 FORCE_REFERENCE(b);
  #             } else {
  #                 // 001
  #                 //case 1: // O -> Y
  #                 if( Y1 ) {
  #                     r = K171;
  #                     g = K85 + third ;
  #                     b = 0;
  #                     FORCE_REFERENCE(b);
  #                 }
  #                 if( Y2 ) {
  #                     r = K170 + third;
  #                     //uint8_t twothirds = (third << 1);
  #                     uint8_t twothirds = scale8( offset8, ((256 * 2) / 3)); // max=170
  #                     g = K85 + twothirds;
  #                     b = 0;
  #                     FORCE_REFERENCE(b);
  #                 }
  #             }
  #         } else {
  #             //01X
  #             // section 2-3
  #             if( !  (hue & 0x20) ) {
  #                 // 010
  #                 //case 2: // Y -> G
  #                 if( Y1 ) {
  #                     //uint8_t twothirds = (third << 1);
  #                     uint8_t twothirds = scale8( offset8, ((256 * 2) / 3)); // max=170
  #                     r = K171 - twothirds;
  #                     g = K170 + third;
  #                     b = 0;
  #                     FORCE_REFERENCE(b);
  #                 }
  #                 if( Y2 ) {
  #                     r = K255 - offset8;
  #                     g = K255;
  #                     b = 0;
  #                     FORCE_REFERENCE(b);
  #                 }
  #             } else {
  #                 // 011
  #                 // case 3: // G -> A
  #                 r = 0;
  #                 FORCE_REFERENCE(r);
  #                 g = K255 - third;
  #                 b = third;
  #             }
  #         }
  #     } else {
  #         // section 4-7
  #         // 1XX
  #         if( ! (hue & 0x40) ) {
  #             // 10X
  #             if( ! ( hue & 0x20) ) {
  #                 // 100
  #                 //case 4: // A -> B
  #                 r = 0;
  #                 FORCE_REFERENCE(r);
  #                 //uint8_t twothirds = (third << 1);
  #                 uint8_t twothirds = scale8( offset8, ((256 * 2) / 3)); // max=170
  #                 g = K171 - twothirds; //K170?
  #                 b = K85  + twothirds;
  #             } else {
  #                 // 101
  #                 //case 5: // B -> P
  #                 r = third;
  #                 g = 0;
  #                 FORCE_REFERENCE(g);
  #                 b = K255 - third;
  #             }
  #         } else {
  #             if( !  (hue & 0x20)  ) {
  #                 // 110
  #                 //case 6: // P -- K
  #                 r = K85 + third;
  #                 g = 0;
  #                 FORCE_REFERENCE(g);
  #                 b = K171 - third;
  #             } else {
  #                 // 111
  #                 //case 7: // K -> R
  #                 r = K170 + third;
  #                 g = 0;
  #                 FORCE_REFERENCE(g);
  #                 b = K85 - third;
  #             }
  #         }
  #     }
  defp determine_rgb({:false,:false,:false}, third, _twothird) do
  #                 r = K255 - third;
  #                 g = third;
  #                 b = 0;
  #                 FORCE_REFERENCE(b);
    {@k255 - third, third, 0}
  end
  defp determine_rgb({:false, :false, :true}, third, _twothird) do
  #                     r = K171;
  #                     g = K85 + third ;
  #                     b = 0;
  #                     FORCE_REFERENCE(b);
    {@k171, @k85 + third, 0}
  end
  defp determine_rgb({:false, :true, :false}, third, twothird) do
  #                     //uint8_t twothirds = (third << 1);
  #                     uint8_t twothirds = scale8( offset8, ((256 * 2) / 3)); // max=170
  #                     r = K171 - twothirds;
  #                     g = K170 + third;
  #                     b = 0;
  #                     FORCE_REFERENCE(b);
    {@k171 - twothird, @k170 + third, 0}
  end
  defp determine_rgb({:false, :true, :true}, third, _twothird) do
  #                 // case 3: // G -> A
  #                 r = 0;
  #                 FORCE_REFERENCE(r);
  #                 g = K255 - third;
  #                 b = third;
    {0, @k255 - third, third}
  end
  defp determine_rgb({:true, :false, :false}, _third, twothird) do
  #                 //case 4: // A -> B
  #                 r = 0;
  #                 FORCE_REFERENCE(r);
  #                 //uint8_t twothirds = (third << 1);
  #                 uint8_t twothirds = scale8( offset8, ((256 * 2) / 3)); // max=170
  #                 g = K171 - twothirds; //K170?
  #                 b = K85  + twothirds;
    {0, @k171 - twothird, @k85 + twothird}
  end
  defp determine_rgb({:true, :false, :true}, third, _twothird) do
  #                 // 101
  #                 //case 5: // B -> P
  #                 r = third;
  #                 g = 0;
  #                 FORCE_REFERENCE(g);
  #                 b = K255 - third;
    {third, 0, @k255 - third}
  end
  defp determine_rgb({:true, :true, :false}, third, _twothird) do
  #                 //case 6: // P -- K
  #                 r = K85 + third;
  #                 g = 0;
  #                 FORCE_REFERENCE(g);
  #                 b = K171 - third;
    {@k85 + third, 0, @k171 - third}
  end
  defp determine_rgb({:true, :true, :true}, third, _twothird) do
  #                 //case 7: // K -> R
  #                 r = K170 + third;
  #                 g = 0;
  #                 FORCE_REFERENCE(g);
  #                 b = K85 - third;
    {@k170 + third, 0, @k85 - third}
  end
end
