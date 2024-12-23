# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Animation.Animator do
  @moduledoc """
  The client often wants to run some animations. This can of course be done by
  repeatedly updating the `Leds` definitions and calling
  `Leds.send()` to send it to the driver.
  This often results in constructs like the following:application
  ```
    Enum.each(1..10, fn index ->
    Leds
      |> led_definition function(index)
      |> Leds.send(config)
      Process.sleep(600)
    end)
   ```
   This creates a loop over some led definition, sends it to the LED strip and then
   waits for a while to do the next step.
   The index can be used for either influencing the led definition function,
   or the offset of the strip and thereby influencing the animation.

  This approach is not really good, because of the following drawbacks:
  * it is difficult to update the animation while it's running,
     because it would require to interrupt the loop
  * the sending to the LED strip can not be optimized, except by knowing
     at which update frequency the driver is updating the strip. Of course it would be
     possible for a client to figure this out, but who would do that?

   The idea of this module is to take care of those concerns by implementing a GenServer that
   runs the loop, but can be updated in-between.

   From the above example it can be seen that two things can be updated:
   * The led_definition_function and
   * The send config (even though we will have to implement that as a
    function too due to the handling of the index)

   Note: the time is not something that can be specified, since the animator will
   be triggered by `Fledex.LedStrip` in it's update frequency. Thus to implement
   some wait pattern, the trigger counter (or some other timer logic) should be used

   Both of them can be set by defining an appropriate function and setting and resetting a reference at will

   This module does not define any functions on its own, because the interface is defined
   by `Fledex.Animation.AnimatorBase`.
  """
  use Fledex.Animation.AnimatorBase

  require Logger

  alias Fledex.Animation.AnimatorBase
  alias Fledex.Leds
  alias Fledex.LedStrip
  alias Fledex.Utils.PubSub

  @type config_t :: %{
          optional(:type) => :animation | :static,
          optional(:def_func) => (map -> Leds.t()),
          optional(:options) => keyword | nil,
          optional(:effects) => [{module, keyword}]
        }

  @type state_t :: %{
          :triggers => map,
          :type => :animation | :static,
          :def_func => (map -> Leds.t()),
          :options => keyword | nil,
          :effects => [{module, keyword}],
          :strip_name => atom,
          :animation_name => atom
        }
  ### MARK: server side
  @impl GenServer
  @spec init({config_t, atom, atom}) :: {:ok, state_t, {:continue, :paint_once}}
  def init({init_args, strip_name, animation_name}) do
    state = %{
      triggers: %{},
      type: :animation,
      def_func: &AnimatorBase.default_def_func/1,
      options: [send_config: &AnimatorBase.default_send_config_func/1],
      effects: [],
      strip_name: strip_name,
      animation_name: animation_name
    }

    state = update_config(state, init_args)

    :ok = LedStrip.define_namespace(state.strip_name, state.animation_name)

    case state.type do
      :animation -> :ok = PubSub.subscribe(PubSub.app(), PubSub.channel_trigger())
      # we don't subscribe because we paint only once
      :static -> :ok
    end

    {:ok, state, {:continue, :paint_once}}
  end

  @impl GenServer
  @spec handle_continue(:paint_once, state_t) :: {:noreply, state_t}
  def handle_continue(:paint_once, state) do
    {:noreply, update_leds(state)}
  end

  @impl GenServer
  @spec handle_info({:trigger, map}, state_t) :: {:noreply, state_t}
  def handle_info({:trigger, triggers}, %{strip_name: strip_name} = state)
      when is_map_key(triggers, strip_name) do
    # we only want to trigger the led update if we have a trigger from the driver (=strip_name as key)
    # otherwise we collect the triggers. Now it's time to merge previously collected triggers in
    state = %{state | triggers: Map.merge(state.triggers, triggers)}
    {:noreply, update_leds(state)}
  end

  def handle_info({:trigger, triggers}, state) do
    # if the trigger is not from the driver (=strip_name as key) we only want to collect
    # the triggers for when we want an update of the leds
    {:noreply, %{state | triggers: Map.merge(state.triggers, triggers)}}
  end

  @spec update_leds(state_t) :: state_t
  defp update_leds(
         %{
           strip_name: strip_name,
           animation_name: animation_name,
           def_func: def_func,
           options: options,
           effects: effects,
           triggers: triggers
         } = state
       ) do
    # IO.puts("Update_Leds1: Key: #{Keyword.has_key?(options, :send_config_func)}")
    send_config_func = options[:send_config] || (&AnimatorBase.default_send_config_func/1)
    # IO.puts("Options: #{inspect options}")
    # this is for compatibility reasons. if only a send_config_func is defined
    # in the options list, then no options are defined. In that case we need to define
    # the options as being nil to call the def_func/1 instead of the def_func/2 function
    options =
      if options != nil and length(options) == 1 and Keyword.has_key?(options, :send_config) do
        nil
      else
        options
      end

    # we can get two different responses, with or without triggers, we make sure our result contains the triggers
    {leds, triggers} = call_def_func(def_func, triggers, options) |> get_with_triggers(triggers)
    context = %{strip_name: strip_name, animation_name: animation_name}
    {leds, triggers} = apply_effects(leds, effects, triggers, context)

    # independent on the configs say we want to ensure we use the correct namespace (animation_name)
    # and server_name (strip_name). Therefore we inject it
    leds = Leds.set_led_strip_info(leds, animation_name, strip_name)
    {config, triggers} = send_config_func.(triggers) |> get_with_triggers(triggers)
    Leds.send(leds, config)
    %{state | triggers: triggers}
  end

  @spec call_def_func(fun, %{atom: any}, keyword) :: Leds.t() | {Leds.t(), %{atom: any}}
  defp call_def_func(def_func, triggers, options)

  defp call_def_func(def_func, triggers, _options) when is_function(def_func, 1),
    do: def_func.(triggers)

  defp call_def_func(def_func, triggers, options) when is_function(def_func, 2),
    do: def_func.(triggers, options)

  @spec apply_effects(Leds.t(), [{module, map}], map, map) :: {Leds.t(), map}
  def apply_effects(leds, effects, triggers, context) do
    count = leds.count

    {led_list, led_count, triggers} =
      Enum.zip_reduce(
        1..length(effects)//1,
        Enum.reverse(effects),
        {Leds.to_list(leds), count, triggers},
        fn index, {effect, config}, {leds, count, triggers} ->
          context = Map.put(context, :effect, index)
          {leds, count, triggers} = effect.apply(leds, count, config, triggers, context)
          {leds, count, triggers}
        end
      )

    {Leds.leds(led_count, led_list, %{}), triggers}
  end

  # the response can be with or without trigger, we ensure that it's always with a trigger,
  # in the worst case with the original triggers.
  @spec get_with_triggers(response :: any | {any, map}, orig_triggers :: map) :: {any, map}
  defp get_with_triggers(response, orig_triggers) do
    case response do
      {something, triggers} -> {something, triggers}
      something -> {something, orig_triggers}
    end
  end

  @doc false
  @spec update_config(state_t, config_t) :: state_t
  def update_config(state, config) do
    %{
      type: config[:type] || state.type,
      triggers: Map.merge(state.triggers, config[:triggers] || state[:triggers]),
      def_func: Map.get(config, :def_func, &AnimatorBase.default_def_func/1),
      options: update_options(config[:options], config[:send_config_func]),
      effects: update_effects(state.effects, config[:effects], state.strip_name),
      # not to be updated
      strip_name: state.strip_name,
      # not to be updated
      animation_name: state.animation_name
    }
  end

  @spec update_options(keyword | nil, fun | nil) :: keyword
  def update_options(options, nil), do: options

  def update_options(options, send_config_func) do
    Keyword.put(options || [], :send_config, send_config_func)
  end

  @spec update_effects([{module, keyword}], [{module, keyword}], atom) :: [{module, keyword}]
  defp update_effects(current_effects, new_effects, strip_name) do
    effects = new_effects || current_effects

    Enum.map(effects, fn {module, configs} ->
      {module, Keyword.put_new(configs, :trigger_name, strip_name)}
    end)
  end

  @impl GenServer
  @spec handle_cast({:config, config_t}, state_t) :: {:noreply, state_t}
  def handle_cast({:config, config}, state) do
    state = update_config(state, config)

    {:noreply, update_leds(state)}
  end

  @impl GenServer
  @spec handle_cast({:update_effect, :all | pos_integer, keyword}, state_t) :: {:noreply, state_t}
  def handle_cast({:update_effect, :all, config_updates}, state) do
    effects = Enum.map(state.effects, fn effect -> update_effect(effect, config_updates) end)
    {:noreply, %{state | effects: effects}}
  end

  def handle_cast({:update_effect, what, config_updates}, %{effects: effects} = state)
      when is_integer(what) and what > 0 do
    {:noreply,
     %{
       state
       | effects:
           update_effect_at(effects, what, config_updates, %{
             strip_name: state.strip_name,
             animation_name: state.animation_name
           })
     }}
  end

  @spec update_effect_at(list({module, config_t}), pos_integer(), keyword, map) :: [
          {module, config_t}
        ]
  defp update_effect_at(effects, what, config_updates, context)
       when is_list(effects) and is_integer(what) and what > 0 do
    what_zero_index = what - 1

    case Enum.at(effects, what_zero_index, nil) do
      nil ->
        Logger.warning("No effect found at index #{inspect(what)} (context: #{inspect(context)})")
        effects

      effect ->
        List.replace_at(effects, what_zero_index, update_effect(effect, config_updates))
    end
  end

  @spec update_effect({module, keyword}, keyword) :: {module, keyword}
  defp update_effect({module, config} = _effect, config_updates)
       when is_atom(module) and is_list(config) do
    {module, Keyword.merge(config, config_updates)}
  end

  @impl GenServer
  @spec terminate(reason, state :: state_t) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(
        _reason,
        %{
          strip_name: strip_name,
          animation_name: animation_name,
          type: type
        } = _state
      ) do
    case type do
      :animation -> PubSub.unsubscribe(PubSub.app(), PubSub.channel_trigger())
      # nothing to do, since we haven't been subscribed
      :static -> :ok
    end

    LedStrip.drop_namespace(strip_name, animation_name)
  end
end
