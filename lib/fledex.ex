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
      # import also the Leds definitions so no namespace is required
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
end
