defmodule Fledex.Test do
  use ExUnit.Case
#   use Fledex
#   alias Fledex.LedsDriver

  describe "test macros" do
    test "simple led strip macro" do
      use Fledex
      # def register(list) do
      #   IO.puts(inspect list)
      # end
      # led_strip do
      #   data -> IO.puts(inspect data)
      # end
      # :ok
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

# some code that could be a bit of a start for some tests
# defmodule F do
#   # def run() do
#   use Fledex

#   led_strip "chain1" do
#     live_loop :john, test: 10, tset: "string1" do
#       data ->
#         data.something
#         # _e = data.something
#         # with_opts test:  10
#         # with_opts tset: "string1"
#         # IO.puts "server_name: #{inspect @server_name}"
#     end

#     live_loop :detti, test: 20, tset: "string2" do
#       data -> data.something + 10
#     end
#   end

#   led_strip "chain2" do
#     live_loop :john, test: 5, tset: "1string" do
#       data -> data.something - 10
#     end
#   end

#   # end
# end
