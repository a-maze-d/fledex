# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

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
  require Logger

  alias Fledex.Utils.Dsl

  # configuration for the different macros/functions that can be used to configure our strip
  # this is also used to configure our Manager to resolve the type to a module
  @config %{
    animation: Animator,
    static: Animator,
    component: Animator, # This is not the correct one yet
    effect: Animator # This is not yet correct. It shouldn't appear here at all, but it makes it work for now
  }
  # @config_keys Map.keys @config

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
  @spec __using__(keyword) :: Macro.t
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Fledex
      # import also the Leds and the color name definitions so no namespace are required
      import Fledex.Leds
      import Fledex.Color.Names

      alias Fledex.Utils.Dsl
      Dsl.init(opts)
    end
  end

  @doc """
    This introduces a new `animation` (animation) that will be played over
    and over again until it is changed.

    Therefore we give it a name to know whether it changes. The `do ... end` block
    needs to define a function. This function receives a trigger as argument, but
    you have two possbilities to implement it.

    * Either you pattern match on the triggers, e.g. something like the following:
    ```elixir
    led_strip :strip, :kino do
      animation :name do
        %{strip: counter} ->
          do_something_with_the_counter(counter)
        triggers ->
          # During init it can happen that the strip trigger is not available yet
          do_something_during init_phase(triggers)
      end
    end
    ```
    * Or, if you don't require the trigger, you can specify it without a trigger, e.g.
    ```elixir
    led_strip :strip, :kino do
      animation :name do
        do_something_without_a_trigger()
      end
    end
    ```
  """
  # @spec animation(atom, keyword | nil, do: Macro.t) :: Macro.t
  defmacro animation(name, options \\ nil, do: block) do
    # decide on whether the user pattern matched or didn't specify an
    # argument at all
    def_func_ast = case block do
      # argument matched, create only an anonymous function around it
      [{:->, _, _}] = block -> {:fn, [], block}
      # argument didn't match, create an argument
      # then create an anonymous function around it
      block -> {:fn, [], [{:->, [], [[{:_triggers, [], Elixir}], block]}]}
    end
    quote do
      Dsl.create_config(
        unquote(name),
        :animation,
        unquote(def_func_ast),
        unquote(options)
      )
    end
    #  |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  # TODO: decide on whether there is a point to have a static version. it could
  #       simply delegate to animation.
  @doc """
  The static macro is equal to the animation macro, but it will not receive any triggers.

  Therefore, there will not be any repainting and the `def_func` will not receive any
  parameter. It will only be painted once at definition time.
  """
  # @spec static(atom, keyword | nil, Macro.t) :: Macro.t
  defmacro static(name, options \\ nil, do: block) do
    # even the static function gets an argument, we create it, because
    # we don't expect one to be provided
    def_func_ast = case block do
      [{:->, _, _}] -> raise ArgumentError, "A static function does not take an argument"
      block -> {:fn, [], [{:->, [], [[{:_triggers, [], Elixir}], block]}]}
    end
    quote do
      Dsl.create_config(
        unquote(name),
        :static,
        unquote(def_func_ast),
        unquote(options)
      )
    end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
  A component is a pre-defined animation that reacts to some input.
  We might have a thermometer component that defines the display of
  a thermometer:

  * input: single value
  * display is a range (positive, 0, negative)
  * ...

  A component does not have a `do ... end` block, since it defines it's
  own animation, and it's only controlled through some parameters that
  can be passed as options like:

  * the value,
  * the display colors,
  * the range of our scale

  Thus, our component would look like the following:
  ```elixir
    alias Fledex.Component.Thermometer
    component :thermo, Thermometer,
      range: -20..40,
      trigger: :temperature,
      negative: :blue,
      null: :may_green,
      positive: :red
  ```
  It is up to each component to define their own set of mandatory and optional
  parameters.
  """
  # @spec component(atom, module, keyword) :: Macro.t
  defmacro component(name, module, opts) do
    quote do
      Dsl.create_config(unquote(name), unquote(module), unquote(opts))
    end
      #  |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
  Add an effect to an animation

  This macro allows to add an effect to an animation (or even a component
  (TODO: figure out whether an effect on a static component makes any sense,
  it would mean that the static component suddenly would need to be animated)

  You simply warp the animation inside a effect block. It's possible to have
  severeal nested effects. In that case they will all be executed in sequence.

  Example:
  ```elixir
  use Fledex
  alias Fledex.Effect.Wanish
  led_strip :john, :kino do
    effect Wanish, trigger_name: :john do
      animation :test do
        _triggers ->
          leds(1) |> light(:red) |> repeat(50)
      end
    end
  end
  ```
  """
  # @spec effect(module, keyword, Macro.t) :: Macro.t
  defmacro effect(module, options \\ [], do: block) do
    configs_ast = Dsl.extract_configs(block)
    quote do
      Dsl.apply_effect(unquote(module), unquote(options), unquote(configs_ast))
    end
      #  |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
    This introduces a new led_strip.
  """
  # @spec led_strip(atom, atom | keyword, Macro.t) :: Macro.t | map()
  defmacro led_strip(strip_name, strip_options \\ :kino, do: block) do
    configs_ast = Dsl.extract_configs(block)

    quote do
      Dsl.configure_strip(
        unquote(strip_name),
        unquote(strip_options),
        unquote(configs_ast)
      )
      end
      # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end
end

defmodule Fledex2.T do
  def t1 do
    use Fledex
    alias Fledex.Effect.Dimming

    effect Rotation do
      animation :john do
        _triggers -> leds(10)
      end
      animation :mary do
        _triggers -> leds(20)
      end
    end
  end
  def t2 do
    use Fledex
    alias Fledex.Effect.Dimming
    alias Fledex.Effect.Rotation

    effect Rotation, [] do
      effect Dimming do
        animation :john do
          _triggers -> leds(10)
        end
      end
      animation :mary do
        _triggers -> leds(20)
      end
    end
  end
  def t3 do
    use Fledex
    led_strip :strip, :debug do
      animation :john3 do
        leds(10)
      end
      animation :mary2 do
        leds(20)
      end
    end
  end
end
