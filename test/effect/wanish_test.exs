defmodule Fledex.Effect.WanishTest do
  use ExUnit.Case

  alias Fledex.Effect.Wanish
  # defp with_triggers(response, orig_triggers) do
  #   result = case response do
  #     {leds, triggers} -> {leds, triggers}
  #     _ -> {response, orig_triggers}
  #   end
  #   result
  # end

  describe "wanish effect" do
    test "without trigger name" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{counter: 1}

      {returned_leds, _triggers} = Wanish.apply(leds, 3, [], triggers)

      assert returned_leds == [0xff0000, 0x00ff00, 0x0000ff]
    end
    test "with trigger name" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{counter: 1}

      {returned_leds, _triggers} = Wanish.apply(leds, 3, [trigger_name: :counter], triggers)

      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]
    end
    test "with right direction" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{default: 1}

      {returned_leds, _triggers} = Wanish.apply(leds, 3, [trigger_name: :default, direction: :right], triggers)

      assert returned_leds == [0xff0000, 0x00ff00, 0x000000]
    end
    test "with divisor" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      triggers = %{default: 1}

      {returned_leds, _triggers} = Wanish.apply(leds, 3, [trigger_name: :default, divisor: 2], triggers)

      assert returned_leds == [0xff0000, 0x00ff00, 0x0000ff]

      triggers = %{default: 2}
      {returned_leds, _triggers} = Wanish.apply(leds, 3, [trigger_name: :default, divisor: 2], triggers)

      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]
    end
    test "with reappear" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      reappear_key = :dummy

      triggers = %{default: 1}
      {returned_leds, triggers} = Wanish.apply(leds, 3, [trigger_name: :default, reappear: true, reappear_key: reappear_key], triggers)
      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]
      assert triggers[reappear_key] == nil

      triggers = %{triggers | default: 2}
      {returned_leds, triggers} = Wanish.apply(leds, 3, [trigger_name: :default, reappear: true, reappear_key: reappear_key], triggers)
      assert returned_leds == [0x000000, 0x000000, 0x0000ff]
      assert triggers[reappear_key] == true

      triggers = %{triggers | default: 3}
      {returned_leds, triggers} = Wanish.apply(leds, 3, [trigger_name: :default, reappear: true, reappear_key: reappear_key], triggers)
      assert returned_leds == [0x000000, 0x000000, 0x000000]
      assert triggers[reappear_key] == true

      triggers = %{triggers | default: 4}
      {returned_leds, triggers} = Wanish.apply(leds, 3, [trigger_name: :default, reappear: true, reappear_key: reappear_key], triggers)
      assert returned_leds == [0x000000, 0x000000, 0x0000ff]
      assert triggers[reappear_key] == true

      triggers = %{triggers | default: 5}
      {returned_leds, triggers} = Wanish.apply(leds, 3, [trigger_name: :default, reappear: true, reappear_key: reappear_key], triggers)
      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]
      assert triggers[reappear_key] == nil

      triggers = %{triggers | default: 6}
      {returned_leds, new_triggers} = Wanish.apply(leds, 3, [trigger_name: :default, reappear: true, reappear_key: reappear_key], triggers)
      assert returned_leds == [0xff0000, 0x00ff00, 0x0000ff]
      assert new_triggers[reappear_key] == nil

      new_triggers = %{new_triggers | default: 7}
      {returned_leds, new_triggers} = Wanish.apply(leds, 3, [trigger_name: :default, reappear: true, reappear_key: reappear_key], new_triggers)
      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]
      assert new_triggers[reappear_key] == nil
    end
    test "with reappear and divisor" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      reappear_key = :dummy
      config = [trigger_name: :default, divisor: 2, reappear: true, reappear_key: reappear_key]

      triggers = %{default: 1}
      {returned_leds, triggers} = Wanish.apply(leds, 3, config, triggers)
      assert returned_leds == [0xff0000, 0x00ff00, 0x0000ff]

      triggers = %{triggers | default: 2}
      {returned_leds, triggers} = Wanish.apply(leds, 3, config, triggers)
      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]

      triggers = %{triggers | default: 3}
      {returned_leds, triggers} = Wanish.apply(leds, 3, config, triggers)
      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]

      triggers = %{triggers | default: 4}
      {returned_leds, triggers} = Wanish.apply(leds, 3, config, triggers)
      assert returned_leds == [0x000000, 0x000000, 0x0000ff]

      triggers = %{triggers | default: 5}
      {returned_leds, triggers} = Wanish.apply(leds, 3, config, triggers)
      assert returned_leds == [0x000000, 0x000000, 0x0000ff]

      triggers = %{triggers | default: 6}
      {returned_leds, new_triggers} = Wanish.apply(leds, 3, config, triggers)
      assert returned_leds == [0x000000, 0x000000, 0x000000]

      new_triggers = %{new_triggers | default: 7}
      {returned_leds, new_triggers} = Wanish.apply(leds, 3, config, new_triggers)
      assert returned_leds == [0x000000, 0x000000, 0x000000]

      new_triggers = %{new_triggers | default: 8}
      {returned_leds, new_triggers} = Wanish.apply(leds, 3, config, new_triggers)
      assert returned_leds == [0x000000, 0x000000, 0x0000ff]

      new_triggers = %{new_triggers | default: 9}
      {returned_leds, new_triggers} = Wanish.apply(leds, 3, config, new_triggers)
      assert returned_leds == [0x000000, 0x000000, 0x0000ff]

      new_triggers = %{new_triggers | default: 10}
      {returned_leds, new_triggers} = Wanish.apply(leds, 3, config, new_triggers)
      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]

      new_triggers = %{new_triggers | default: 11}
      {returned_leds, new_triggers} = Wanish.apply(leds, 3, config, new_triggers)
      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]

      new_triggers = %{new_triggers | default: 12}
      {returned_leds, new_triggers} = Wanish.apply(leds, 3, config, new_triggers)
      assert returned_leds == [0xff0000, 0x00ff00, 0x0000ff]

      new_triggers = %{new_triggers | default: 13}
      {returned_leds, new_triggers} = Wanish.apply(leds, 3, config, new_triggers)
      assert returned_leds == [0xff0000, 0x00ff00, 0x0000ff]

      new_triggers = %{new_triggers | default: 14}
      {returned_leds, _new_triggers} = Wanish.apply(leds, 3, config, new_triggers)
      assert returned_leds == [0x000000, 0x00ff00, 0x0000ff]
    end
  end
end
