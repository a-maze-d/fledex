# NOTE: This module is very much in a brain-storming phase and surely will not work
# yet. The best is if you ignore it for now :-)
defmodule Fledex2 do
  defmacro __using__(_opts) do
    quote do
      import Fledex2
      Module.register_attribute(__MODULE__, :strip_name, accumulate: false)
      Module.register_attribute(__MODULE__, :strip_opts, accumulate: false)
      Module.register_attribute(__MODULE__, :loops, accumulate: true)
      @before_compile Fledex2
    end
  end

  defmacro live_loop(loop_name, loop_options \\ [], do: block) do
    func_ast = {:fn, [], block}
    quote do
      loop_options = unquote(loop_options)
      Module.put_attribute(__MODULE__, :loops, {
        Module.get_attribute(__MODULE__, :strip_name, :default),
        Module.get_attribute(__MODULE__, :strip_options, []),
        unquote(loop_name),
        loop_options,
        unquote(func_ast),
        Keyword.get(loop_options, :registration_handler, &register/5)        
       })
    end # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  defmacro led_strip(strip_name \\ :default, strip_options \\ [], do: block) do
    quote do
      Module.put_attribute(__MODULE__, :strip_name, unquote(strip_name))
      Module.put_attribute(__MODULE__, :strip_options, unquote(strip_options))
      unquote(block)
    end # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end
  def register(loops\\[]) do
    # IO.puts("register: #{inspect loops}")
    loops = Enum.reverse(loops) # bring to orig order
    for {strip_name, strip_options, loop_name, loop_options, func, registration_handler} <- loops do
      # IO.puts("\tregister: #{inspect loop}")
      registration_handler.(strip_name, strip_options, loop_name, loop_options, func)
    end
  end
  def register(strip_name, strip_options, loop_name, loop_options, func) do
    result = func.(%{something: 10})
      IO.puts("strip_name: #{inspect strip_name}, strip_options: #{inspect strip_options}, loop_name: #{inspect loop_name}, options: #{inspect loop_options}, expression: #{inspect func}, result: #{result}")
  end
  def pre_define_live_loops() do

  end
  def post_define_live_loops() do

  end
  # defp check_env(_server_name, _name) do
  #   # is the server running (with the specified name)?
  #   # do we have a Leds defined (with the specified name)?
  # end

  defmacro __before_compile__(env) do
    IO.puts("compiling now...")
    register(Module.get_attribute(env.module, :loops))
  end

end

defmodule F2 do
  # def run() do
    use Fledex2
    led_strip "chain1" do
      live_loop :john, test: 10, tset: "string1" do
        data -> data.something
        # _e = data.something
        # with_opts test:  10
        # with_opts tset: "string1"
        # IO.puts "server_name: #{inspect @server_name}"
      end
      live_loop :detti, test: 20, tset: "string2" do
        data -> data.something + 10
      end
    end
    led_strip "chain2" do
      live_loop :john, test: 5, tset: "1string" do
        data -> data.something - 10
      end
    end
  # end
end
