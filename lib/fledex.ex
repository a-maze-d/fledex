defmodule Fledex do
  @moduledoc """
  This module should provide some simple macros that allow to define the
  led strip and to update it. The code you would write (in livebook) would
  look something like the following:
  ``` elixir
    use Fledex
    led_strip :strip_name, ;kino do
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

  alias Fledex.Animation.Animator
  alias Fledex.Animation.Base
  alias Fledex.Animation.Manager

  # configuration for the different macros/functions that can be used to configure our strip
  # this is also used to configure our Manager to resolve the type to a module
  @config %{
    animation: Animator,
    static: Animator,
    component: Animator # This is not the correct one yet
  }
  @config_keys Map.keys @config

  @doc """
  This function returns the currently configured macros/functions that can be used in a fledex led_strip
  """
  @spec fledex_config :: %{atom => module}
  def fledex_config do
    @config
  end

  @doc"""
  By using this module, the `Fledex` macros are made available.

  This macro does also include the `Fledex.Leds` and the `Fledex.Color.Names` and are
  therefore available without namespace.

  Take a look at the various [livebook examples](readme-2.html) on how to use the Fledex macros
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Fledex
      # import also the Leds and the color name definitions so no namespace are required
      import Fledex.Leds
      import Fledex.Color.Names
      # let's start our animation manager. The manager makes sure only one will be started
      if not Keyword.get(opts, :dont_start, false) do
        Manager.start_link(fledex_config())
      end
    end
  end

  @doc """
    This introduces a new `animation` (animation) that will be played over
    and over again until it is changed.

    Therefore we give it a name to know whether it changes
  """
  defmacro animation(name, options \\ [], do: block) do
    def_func_ast = {:fn, [], block}
    send_config = options[:send_config]  || &Base.default_send_config_func/1
    # Logger.warning(inspect block)
    quote do
      {
       unquote(name),
        %{
          type: :animation,
          def_func: unquote(def_func_ast),
          send_config_func: unquote(send_config),
          effects: []
        }
      }
    end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
  The static macro is equal to the animation macro, but it will not receive any triggers.

  Therefore, there will not be any repainting and the `def_func` will not receive any
  parameter. It will only be painted once at definition time.
  """
  defmacro static(name, options \\ [], do: block) do
    def_func_ast = {:fn, [], [{:->, [], [[{:_triggers, [], Elixir}], block]}]}
    send_config = options[:send_config]  || &Base.default_send_config_func/1
    quote do
      {
        unquote(name),
        %{
          type: :static,
          def_func: unquote(def_func_ast),
          send_config_func: unquote(send_config),
          effects: []
        }
      }
    end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end
  @doc """
  NOT YET IMPLEMENTED (thus, those are just some thoughts)

  A component is a pre-defined animation that reacts to some input.
  We might have a thermometer component that defines the display of
  a thermometer:

  * input: single value
  * display is a range (positive, 0, negative)
  * ...

  The `do: block` should retun the expected parameters for the component.
  For our thermometer component the parameters might be:

  * the value,
  * the display colors,
  * the range of our scale

  Thus, it might look something like the following:
  ```elixir
  do
    %Thermometer{
      value: 10,
      negative: :blue,
      positive: :red,
      range: -10..30,
      steps: 1,
    }
  end
  ```
  """
  defmacro component(_name, _type, _options \\ [], do: _block) do
      # TODO: Add a component macro
  end

  defmacro effect(module, options \\ [], do: block) do
    quote do
      {name, config} = unquote(block)
       {
        name,
        %{config | effects: [{unquote(module), unquote(Macro.escape(options))} | config.effects]}
      }
    end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
    This introduces a new led_strip.
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
      Manager.register_strip(strip_name, strip_options)
      Manager.register_animations(strip_name, Map.new(unquote(configs_ast)))
    end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end
end
