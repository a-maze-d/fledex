# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
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

  @doc """
  By using this module, the `Fledex` macros are made available.

  This macro does also include the `Fledex.Leds` and the `Fledex.Color.Names` and are
  therefore available without namespace.

  Take a look at the various [livebook examples](readme-2.html) on how to use the Fledex macros
  """
  @spec __using__(keyword) :: Macro.t()
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
    def_func_ast = Dsl.ast_add_argument_to_func_if_missing(block)

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

  @doc """
  The static macro is equal to the animation macro, but it will not receive any triggers.

  Therefore, there will not be any repainting and the `def_func` will not receive any
  parameter. It will only be painted once at definition time.
  """
  # @spec static(atom, keyword | nil, Macro.t) :: Macro.t
  defmacro static(name, options \\ nil, do: block) do
    # even the static function gets an argument, we create it, because
    # we don't expect one to be provided
    def_func_ast = Dsl.ast_add_argument_to_func(block)

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
  own animation(s), and it's only controlled through some parameters that
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
    configs_ast = Dsl.ast_extract_configs(block)

    quote do
      Dsl.apply_effect(unquote(module), unquote(options), unquote(configs_ast))
    end

    #  |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
  A job is a [cron job](https://en.wikipedia.org/wiki/Cron) that will trigger in regular
  intervals (depending on the pattern specified). You can run any function and the most
  likely event you will trigger is to publish an event to the triggers (see the [weather
  example livebook](5_fledex_weather_example.livemd)):

  ```elixir
  Fledex.Utils.PubSub.broadcast(:fledex, "trigger", {:trigger, %{temperature: -15.2}})
  ```
  """
  defmacro job(name, pattern, do: block) do
    # IO.puts("#{inspect name}, #{inspect pattern}, #{inspect block}")
    ast_func = Dsl.ast_create_anonymous_func([], block)
    # ast_func = {:fn, [], block}
    quote do
      Dsl.create_job(
        unquote(name),
        unquote(pattern),
        unquote(ast_func)
      )
    end

    # |> tap(& IO.puts Code.format_string! Macro.to_string &1)
  end

  @doc """
    This introduces a new led_strip.
  """
  # @spec led_strip(atom, atom | keyword, Macro.t) :: Macro.t | map()
  defmacro led_strip(strip_name, strip_options \\ :kino, do: block) do
    configs_ast = Dsl.ast_extract_configs(block)

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
