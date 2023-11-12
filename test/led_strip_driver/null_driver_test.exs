defmodule Fledex.LedStripDriver.NullDriverTest do
  use ExUnit.Case, async: true

  alias Fledex.LedStripDriver.NullDriver

  describe "null driver basic tests" do
    test "init" do
      assert NullDriver.init(%{}) == %{}
    end
    test "reinit" do
      assert NullDriver.reinit(%{}) == %{}
    end
    test "transfer" do
      leds = [0xff0000, 0x00ff00, 0x0000ff]
      assert NullDriver.transfer(leds, 0, %{}) == {%{}, :ok}
    end
    test "terminate" do
      assert NullDriver.terminate(:normal, %{}) == :ok
    end
  end
end
