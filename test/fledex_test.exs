defmodule Fledex.Test do
  use ExUnit.Case

  @server_name :john
  describe "test macros" do
    test "simple led strip macro" do
      # ensure our servers are not started
      assert GenServer.whereis(@server_name) == nil
      assert GenServer.whereis(Fledex.LedAnimationManager) == nil

      use Fledex
      led_strip @server_name do
        # we don't define here anything
      end

      # did the correct servers get started?
      assert GenServer.whereis(@server_name) != nil
      assert GenServer.whereis(Fledex.LedAnimationManager) != nil

      # cleanup
      GenServer.stop(Fledex.LedAnimationManager)

      assert GenServer.whereis(@server_name) == nil
      assert GenServer.whereis(Fledex.LedAnimationManager) == nil
    end

    test "simple live_loop macro" do
      use Fledex
      live_loop :merry do
        data -> IO.puts(inspect data)
      end
#       end
# #       live_loop :john do
# #         call_test_function()
# #       end
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
