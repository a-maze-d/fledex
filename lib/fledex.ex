# NOTE: This module is very much in a brain-storming phase and surely will not work
# yet. The best is if you ignore it for now :-)
defmodule Fledex do
  @moduledoc """
  This module should provide some simple macros that allow to define the
  led strip and to update it. The code you would write (in livebook) would
  look something like the following:
  iex> use Fledex
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
  require Logger

  defmacro __using__(opts) do
    opts = if Macro.quoted_literal?(opts) do
      Macro.prewalk(opts, &expand_alias(&1, __CALLER__))
    else
      opts
    end

    quote bind_quoted: [opts: opts] do
      import Fledex
      import Fledex.Leds
      # let's start our animation manager. The manager makes sure only one will be started
      Fledex.LedAnimationManager.start_link()
    end
  end

  defp expand_alias({:__aliases__, _meta, _args} = alias, env) do
    Macro.expand(alias, %{env | function: {:action, 2}})
  end
  defp expand_alias(other, _env), do: other

  @doc """
    This introduces a new `live_loop` (animation) that will be played over
    and over again until it is changed. Therefore we we give it a name to
    know whether it changes
  """
  defmacro live_loop(loop_name, loop_options \\ [], do: block) do
    def_func_ast = {:fn, [], block}
    send_config = loop_options[:send_config]  || &Fledex.LedAnimator.default_send_config_func/1
    # Logger.warning(inspect block)
    quote do
      {
       unquote(loop_name),
        %{
          def_func: unquote(def_func_ast),
          send_config_func: unquote(send_config)
        }
      }
    end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)

    # quote do
    #   Module.put_attribute(:strip1, :loops, {
    #     Module.get_attribute(:strip1, :strip_name, __MODULE__),
    #     Module.get_attribute(:strip1, :strip_options, []),
    #     unquote(loop_name),
    #     unquote(loop_options),
    #     unquote(func_ast),
    #   })
    # end
    # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
    This introduces a new led_strip. Probably we only have a single
    led strip and then the default name (the module name) will be used.
  """
  defmacro led_strip(strip_name, strip_options \\ :kino, do: block) do
    # Logger.error(inspect block)
    {_ast, configs_ast} = Macro.prewalk(block, [], fn
       {:live_loop, meta, children}, acc -> {{:live_loop, meta, children}, [{:live_loop, meta, children} | acc]}
       other, acc -> {other, acc}
    end)
    # Logger.error(inspect configs_ast)

    quote do
      strip_name = unquote(strip_name)
      strip_options = unquote(strip_options)
      Fledex.LedAnimationManager.register_strip(strip_name, strip_options)
      Fledex.LedAnimationManager.register_animations(strip_name, Map.new(unquote(configs_ast)))
    end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  # def create_map(config) do
  #   # Logger.info("Config: #{inspect config}")
  #   Map.new(config)
  #   # Logger.info("Map: #{inspect map}")
  # end

  # @doc """
  #   After parsing the Dsl the collected definitions will be passed to this function
  #   wich will process each definition by calling the specified callback functions
  # """
  # @impl Fledex.Callbacks
  # def register(loops \\ []) do
  #   # IO.puts("register: #{inspect loops}")
  #   # bring to orig order
  #   loops = Enum.reverse(loops)

  #   for {strip_name, strip_options, loop_name, loop_options, func} = loop <- loops do
  #     IO.puts("\tregister: #{inspect loop}")
  #     register(strip_name, strip_options, loop_name, loop_options, func)
  #   end
  #   :ok
  # end

  # @doc """
  #   This is the default implementation of the register function that will
  #   search for the LED strip (LedDriver) and the defined live_loop (LedAnimator) and update them according
  #   to the definitions
  # """
  # @impl Fledex.Callbacks
  # def register(strip_name, strip_options, loop_name, loop_options, func) do
  #   result = func.(%{something: 10})

  #   Logger.info("
  #     strip_name: #{inspect(strip_name)},
  #     strip_options: #{inspect(strip_options)},
  #     loop_name: #{inspect(loop_name)},
  #     options: #{inspect(loop_options)},
  #     expression: #{inspect(func)}, result: #{result}
  #   ")
  # end

  # def pre_define_live_loops do
  # end

  # def post_define_live_loops do
  # end

  # defp check_env(_server_name, _name) do
  #   # is the server running (with the specified name)?
  #   # do we have a Leds defined (with the specified name)?
  # end

  # defmacro __before_compile__(_env) do
  #   IO.puts("compiling now...")
  #   Logger.error("compiling now...")
  #   loops = Module.get_attribute(:strip1, :loops)
  #   quote do
  #     defmodule T do
  #       def run do
  #         register(unquote(Macro.escape(loops)))
  #       end
  #     end
  #   end
  #   |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  # end
end

defmodule Fledex.Runner do
  def run do
    use Fledex
    led_strip :john do
      live_loop :jane, send_config: fn _triggers -> %{} end do
        _triggers -> Fledex.Leds.new(30)
      end
      live_loop :marry, send_config: fn _triggers -> %{} end do
        _triggers -> Fledex.Leds.new(40)
      end
    end

  end
  def loop do
    use Fledex
    live_loop :fiona, send_config: fn _triggers -> %{} end do
      _triggers -> Fledex.Leds.new(30)
    end
  end
end
