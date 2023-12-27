defmodule Fledex.Component.Thermometer do

  # alias Fledex.Animation.Base
  alias Fledex.Leds

  def configure(options) do
    %{
      type: :animation,
      def_func: &def_func/2,
      # send_config_func: &Base.default_send_config_func/1,
      options: options,
      effects: []
    }
  end

  defp def_func(triggers, _options) do
    temp = triggers[:temperature] || 100
    temp = round(temp)

    temp =
      if temp == 100 do
        100
      else
        temp = min(temp, 40)
        max(temp, -20)
      end

    {leds, offset} =
      case temp do
        temp when temp == 100 ->
          {Leds.leds(61)
            |> Leds.light(:blue, 1, 20)
            |> Leds.light(:may_green)
            |> Leds.light(:red, 22, 40), 1}

        temp when temp < 0 and temp > -20 ->
          {Leds.leds(1) |> Leds.light(:blue) |> Leds.repeat(-temp), 21 + temp}

        temp when temp == 0 ->
          {Leds.leds(1) |> Leds.light(:may_green), 21}

        temp when temp > 0 ->
          {Leds.leds(1) |> Leds.light(:red) |> Leds.repeat(temp), 22}
      end

    Leds.leds(61) |> Leds.light(leds, offset)
  end
end
