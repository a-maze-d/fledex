defmodule Fledex do
  @moduledoc """
  This module should provide some simple macros that allow to define the
  led strip and to update it. The code you would write (in livebook) would
  look something like the following:
  ``` elixir
    use Fledex
    led_strip :strip_name do
      animation :john do
        config = %{
          num_leds: 50,
          reversed: true
        }

        leds(50)
          |> rainbow(config)
      end
    end
  ```
  """

  alias Fledex.Animation.BaseAnimation
  alias Fledex.Animation.LedAnimationManager
  alias Fledex.Animation.LedAnimator

  # configuration for the different macros/functions that can be used to configure our strip
  # this is also used to configure our LedAnimationManager to resolve the type to a module
  @config %{
    animation: LedAnimator,
    static: LedAnimator,
    component: LedAnimator # This is not the correct one yet
  }
  @config_keys Map.keys @config

  @doc """
  This function returns the currently configured macros/functions that can be used in a fledex led_strip
  """
  def fledex_config do
    @config
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Fledex
      # import also the Leds and the color name definitions so no namespace are required
      import Fledex.Leds
      import Fledex.Color.Names
      # let's start our animation manager. The manager makes sure only one will be started
      if not Keyword.get(opts, :dont_start, false) do
        LedAnimationManager.start_link(fledex_config())
      end
    end
  end

  @doc """
    This introduces a new `animation` (animation) that will be played over
    and over again until it is changed. Therefore we we give it a name to
    know whether it changes
  """
  defmacro animation(name, options \\ [], do: block) do
    def_func_ast = {:fn, [], block}
    send_config = options[:send_config]  || &BaseAnimation.default_send_config_func/1
    # Logger.warning(inspect block)
    quote do
      {
       unquote(name),
        %{
          type: :animation,
          def_func: unquote(def_func_ast),
          send_config_func: unquote(send_config)
        }
      }
    end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
  The static macro is equal to the animation macro, but it will not receive any triggers. Therefore,
  there will not be any repainting and the `def_func` will not receive any parameter.
  It will only be painted once at definition time.
  """
  defmacro static(name, options \\ [], do: block) do
    def_func_ast = {:fn, [], [{:->, [], [[{:_triggers, [], Elixir}], block]}]}
    send_config = options[:send_config]  || &BaseAnimation.default_send_config_func/1
    quote do
      {
        unquote(name),
        %{
          type: :static,
          def_func: unquote(def_func_ast),
          send_config_func: unquote(send_config)
        }
      }
    end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end
  defmacro component(_name, _type, _options \\ []) do
      # TODO: Add a component macro
  end

  @doc """
    This introduces a new led_strip. Probably we only have a single
    led strip and then the default name (the module name) will be used.
  """
  defmacro led_strip(strip_name, strip_options \\ :kino, do: block) do
    # Logger.error(inspect block)
    {_ast, configs_ast} = Macro.prewalk(block, [], fn
       {type, meta, children}, acc when type in @config_keys -> {{type, meta, children}, [{type, meta, children} | acc]}
       other, acc -> {other, acc}
    end)
    # Logger.error(inspect configs_ast)

    quote do
      strip_name = unquote(strip_name)
      strip_options = unquote(strip_options)
      LedAnimationManager.register_strip(strip_name, strip_options)
      LedAnimationManager.register_animations(strip_name, Map.new(unquote(configs_ast)))
    end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

end
