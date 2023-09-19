# NOTE: This module is very much in a brain-storming phase and surely will not work
# yet. The best is if you ignore it for now :-)
defmodule Fledex do
  @behaviour Fledex.Callbacks
  @moduledoc """
  This module should provide some simple macros that allow to define the
  led strip and to update it. The code you would write (in livebook) would
  look something like the following:
  iex> led_strip do
          live_loop :john, send_config: %{offset: counter}, delay_config: counter do
            config = %{
              num_leds: 50,
              reversed: true
            }

            Leds.new(50)
              |> Leds.func(:rainbow, config)
          end
      end
  """
  defmacro __using__(_opts) do
    quote do
      import Fledex
      Module.register_attribute(__MODULE__, :strip_name, accumulate: false)
      Module.register_attribute(__MODULE__, :strip_opts, accumulate: false)
      Module.register_attribute(__MODULE__, :loops, accumulate: true)
      @before_compile
    end
  end

  @doc """
    This introduces a new `live_loop` (animation) that will be played over
    and over again until it is changed. Therefore we we give it a name to
    know whether it changes
  """
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
      })
    end

    # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
    This introduces a new led_strip. Probably we only have a single
    led strip and then the default name (the module name) will be used.
  """
  defmacro led_strip(strip_name \\ :default, strip_options \\ [], do: block) do
    quote do
      Module.put_attribute(__MODULE__, :strip_name, unquote(strip_name))
      Module.put_attribute(__MODULE__, :strip_options, unquote(strip_options))
      unquote(block)
    end # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
    After parsing the Dsl the collected definitions will be passed to this function
    wich will process each definition by calling the specified callback functions
  """
  @impl Fledex.Callbacks
  def register(loops \\ []) do
    # IO.puts("register: #{inspect loops}")
    # bring to orig order
    loops = Enum.reverse(loops)

    for {strip_name, strip_options, loop_name, loop_options, func} <- loops do
      # IO.puts("\tregister: #{inspect loop}")
      register(strip_name, strip_options, loop_name, loop_options, func)
    end
    :ok
  end

  @doc """
    This is the default implementation of the register function that will
    search for the LED strip (LedDriver) and the defined live_loop (LedAnimator) and update them according
    to the definitions
  """
  @impl Fledex.Callbacks
  def register(strip_name, strip_options, loop_name, loop_options, func) do
    result = func.(%{something: 10})

    IO.puts(
      "strip_name: #{inspect(strip_name)}, strip_options: #{inspect(strip_options)}, loop_name: #{inspect(loop_name)}, options: #{inspect(loop_options)}, expression: #{inspect(func)}, result: #{result}"
    )
  end

  def pre_define_live_loops do
  end

  def post_define_live_loops do
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
