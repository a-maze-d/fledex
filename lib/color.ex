defmodule Fledex.Color do
  import Bitwise

  defmodule ColorCorrection do
    def typicalSMD5050(),     do: 0xFFB0F0 # 255, 176, 240
    def typicalLEDStrip(),    do: 0xFFB0F0 # 255, 176, 240
    def typical8mmPixel(),    do: 0xFFE08C # 255, 224, 140
    def typicalPixelString(), do: 0xFFE08C # 255, 224, 140
    def uncorrectedColor(),   do: 0xFFFFFF # 255, 255, 255
  end

  defmodule TemperatureCorrection do
      # Black Body Radiators
      def candle(),         do: 0xFF9329 # 1900 K, 255, 147, 41 */,
      def tungsten40W(),    do: 0xFFC58F # 2600 K, 255, 197, 143 */,
      def tungsten100W(),   do: 0xFFD6AA # 2850 K, 255, 214, 170 */,
      def halogen(),        do: 0xFFF1E0 # 3200 K, 255, 241, 224 */,
      def carbonArc(),      do: 0xFFFAF4 # 5200 K, 255, 250, 244 */,
      def highNoonSun(),    do: 0xFFFFFB # 5400 K, 255, 255, 251 */,
      def directSunlight(), do: 0xFFFFFF # 6000 K, 255, 255, 255 */,
      def overcastSkyc(),   do: 0xC9E2FF # 7000 K, 201, 226, 255 */,
      def clearBlueSky(),   do: 0x409CFF # 20000 K, 64, 156, 255 */,

      # Gaseous Light Sources
      # Warm (yellower) flourescent light bulbs
      def warmFluorescent(),          do: 0xFFF4E5 # 0 K, 255, 244, 229 */,
      # Standard flourescent light bulbs
      def standardFluorescent(),      do: 0xF4FFFA # 0 K, 244, 255, 250 */,
      # Cool white (bluer) flourescent light bulbs
      def coolWhiteFluorescent(),     do: 0xD4EBFF # 0 K, 212, 235, 255 */,
      # Full spectrum flourescent light bulbs
      def fullSpectrumFluorescent(),  do: 0xFFF4F2 # 0 K, 255, 244, 242 */,
      # Grow light flourescent light bulbs
      def growLightFluorescent(),     do: 0xFFEFF7 # 0 K, 255, 239, 247 */,
      # Black light flourescent light bulbs
      def blackLightFluorescent(),    do: 0xA700FF # 0 K, 167, 0, 255 */,
      # Mercury vapor light bulbs
      def mercuryVapor(),             do: 0xD8F7FF # 0 K, 216, 247, 255 */,
      # Sodium vapor light bulbs
      def sodiumVapor(),              do: 0xFFD1B2 # 0 K, 255, 209, 178 */,
      # Metal-halide light bulbs
      def metalHalide(),              do: 0xF2FCFF # 0 K, 242, 252, 255 */,
      # High-pressure sodium light bulbs
      def highPressureSodium(),       do: 0xFFB74C # 0 K, 255, 183, 76 */,

      # Uncorrected temperature (0xFFFFFF)
      def uncorrectedTemperature(),   do: 0xFFFFFF # 255, 255, 255 */
  end

  def define_correction(scale, color_correction, temperature_correction) when scale > 0 do
    # /// Calculates the combined color adjustment to the LEDs at a given scale, color correction, and color temperature
    # /// @param scale the scale value for the RGB data (i.e. brightness)
    # /// @param colorCorrection color correction to apply
    # /// @param colorTemperature color temperature to apply
    # /// @returns a CRGB object representing the adjustment, including color correction and color temperature
    # static CRGB computeAdjustment(uint8_t scale, const CRGB & colorCorrection, const CRGB & colorTemperature) {
    #   #if defined(NO_CORRECTION) && (NO_CORRECTION==1)
    #           return CRGB(scale,scale,scale);
    #   #else
    #           CRGB adj(0,0,0);
    #           if(scale > 0) {
    #               for(uint8_t i = 0; i < 3; ++i) {
      {ccr, ccg, ccb} = split_colors(color_correction)
      {tcr, tcg, tcb} = split_colors(temperature_correction)

      r = calculate_color_correction(scale, ccr, tcr)
      g = calculate_color_correction(scale, ccg, tcg)
      b = calculate_color_correction(scale, ccb, tcb)

      {r, g, b}
    #               }
    #           }

    #           return adj;
    #   #endif
    # }
  end
  def define_correction(_, _ , _) do
    {0, 0, 0}
  end

  defp split_colors(rgb) do
    r = (rgb &&& 0xFF0000) >>> 16
    g = (rgb &&& 0x00FF00) >>> 8
    b = rgb &&& 0x0000FF

    {r, g, b}
  end
  defp calculate_color_correction(scale, cc, ct) do
    #                   uint8_t cc = colorCorrection.raw[i];
    #                   uint8_t ct = colorTemperature.raw[i];
    #                   if(cc > 0 && ct > 0) {
    #                       uint32_t work = (((uint32_t)cc)+1) * (((uint32_t)ct)+1) * scale;
    #                       work /= 0x10000L;
    #                       adj.raw[i] = work & 0xFF;
    #                   }
    if cc > 0 && ct > 0 do
      work = (cc+1) * (ct+1) * scale
      work = work / 0x10000
      Kernel.trunc(work) &&& 0xFF
    else
      0
    end
  end
end
