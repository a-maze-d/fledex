defmodule Fledex.Color.Correction do
  import Bitwise
  use Fledex.Color.Types

  alias Fledex.Color.Utils

  defmodule Color do
    def typicalSMD5050(),     do: 0xFFB0F0 # 255, 176, 240
    def typicalLEDStrip(),    do: 0xFFB0F0 # 255, 176, 240
    def typical8mmPixel(),    do: 0xFFE08C # 255, 224, 140
    def typicalPixelString(), do: 0xFFE08C # 255, 224, 140
    def uncorrectedColor(),   do: 0xFFFFFF # 255, 255, 255
  end

  defmodule Temperature do
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

  @spec color_correction_g2(rgb) :: rgb
  def color_correction_g2({r, g, b}) do
    {r, g >>> 2, b}
  end
  @spec color_correction_none(rgb) :: rgb
  def color_correction_none({r,g,b}) do
      {r, g, b}
  end


  @spec define_correction(byte, colorint, colorint) :: rgb
  def define_correction(scale \\ 255, color_correction, temperature_correction)
  def define_correction(scale, color_correction, temperature_correction) when scale > 0 do
      {ccr, ccg, ccb} = Utils.split_into_subpixels(color_correction)
      {tcr, tcg, tcb} = Utils.split_into_subpixels(temperature_correction)

      r = calculate_color_correction(scale, ccr, tcr)
      g = calculate_color_correction(scale, ccg, tcg)
      b = calculate_color_correction(scale, ccb, tcb)

      {r, g, b}
  end
  def define_correction(_, _ , _) do
    {0, 0, 0}
  end

  @spec no_color_correction() :: rgb
  def no_color_correction() do
    # This should correspond to 255, but we do the proper calculation at compile time
    define_correction(Color.uncorrectedColor, Temperature.uncorrectedTemperature)
  end


  @spec apply_rgb_correction(list(rgb), (byte | rgb)) :: list(rgb)
  def apply_rgb_correction(leds, {255,255,255}), do: leds
  def apply_rgb_correction(leds, 0xFFFFFF), do: leds
  def apply_rgb_correction(leds, correction) do
    Enum.map(leds, fn (led) ->
      Utils.nscale8(led, correction, false)
    end)
  end

  @spec calculate_color_correction(byte, byte, byte) :: byte
  def calculate_color_correction(scale, cc, ct) when cc> 0 and ct>0 do
    work = (cc+1) * (ct+1) * scale
    work = work / 0x10000
    Kernel.trunc(work) &&& 0xFF
  end
  def calculate_color_correction(_, _, _), do: 0
end
