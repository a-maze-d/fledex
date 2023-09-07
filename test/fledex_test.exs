defmodule Fledex.Test do
  use ExUnit.Case
#   use Fledex
#   alias Fledex.LedsDriver

  describe "test macros" do
    test "simple led strip macro" do
#       assert Process.whereis(LedsDriver) == nil
#       led_strip do
#         pid = Process.whereis(LedsDriver)
#         assert pid != nil
#         assert Process.alive?(pid) == true
#       end
    end
    test "simple live_loop macro" do
#       live_loop :john do
#         call_test_function()
#       end
    end
  end
end
