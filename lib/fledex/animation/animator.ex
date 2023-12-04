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

   Note: the time is not something that can be specified, since the animator will be triggered by
   `LedsDriver` in it's update frequency. Thus to implement some wait pattern, the trigger counter (or some
   other timer logic) should be used

   Both of them can be set by defining an appropriate function and setting and resetting a reference at will

   This module does not define any functions on its own, because the interface is defined
   by `Fledex.Animation.Base`.
  """
  use Fledex.Animation.Base

  require Logger

  alias Fledex.Animation.Base
  alias Fledex.Leds
  alias Fledex.LedsDriver
  alias Fledex.Utils.PubSub

  @type config_t :: %{
      optional(:type) => atom,
      optional(:def_func) => (map -> Leds.t),
      optional(:send_config_func) => (map -> map),
      optional(:counter) => integer,
      optional(:timer_ref) => reference | nil,
      optional(:strip_name) => atom,
      optional(:animation_name) => atom
    }

  @type state_t :: %{
    :triggers => map,
    :type => atom,
    :def_func => ((integer) -> Leds.t()),
    :send_config_func => ((integer) -> map()),
    :strip_name => atom,
    :animation_name => atom
  }
  ### server side
  @impl GenServer
  @spec init({config_t, atom, atom}) :: {:ok, state_t, {:continue, :paint_once}}
  def init({init_args, strip_name, animation_name}) do
    state = %{
      triggers: %{},
      type: :animation,
      def_func: &Base.default_def_func/1,
      send_config_func: &Base.default_send_config_func/1,
      strip_name: strip_name,
      animation_name: animation_name
    }
    state = update_config(state, init_args)

    :ok= LedsDriver.define_namespace(state.strip_name, state.animation_name)
    case state.type do
      :animation -> :ok = PubSub.subscribe(:fledex, "trigger")
      :static -> :ok # we don't subscribe because we paint only once
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
    %{state | triggers: Map.merge(state.triggers, triggers)}
    {:noreply, update_leds(state)}
  end
  def handle_info({:trigger, triggers}, state) do
    # if the trigger is not from the driver (=strip_name as key) we only want to collect
    # the triggers for when we want an update of the leds
    {:noreply, %{state | triggers: Map.merge(state.triggers, triggers)}}
  end

  @spec update_leds(state_t) :: state_t
  defp update_leds(%{
    strip_name: strip_name,
    animation_name: animation_name,
    def_func: def_func,
    send_config_func: send_config_func,
    triggers: triggers} = state) do
      # we can get two different responses, with or without triggers, we make sure our result contains the triggers
      {leds, triggers} = def_func.(triggers) |> get_with_triggers(triggers)
      # independent on the configs say we want to ensure we use the correct namespace (animation_name)
      # and server_name (strip_name). Therefore we inject it
      leds = Leds.set_driver_info(leds, animation_name, strip_name)
      {config, triggers} = send_config_func.(triggers) |> get_with_triggers(triggers)
      Leds.send(leds, config)
      %{state | triggers: triggers}
  end
  # the response can be with or without trigger, we ensure that it's always with a trigger,
  # in the worst case with the original triggers.
  @spec get_with_triggers(response :: map | {map, map}, map) :: {map, map}
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
      def_func: Map.get(config, :def_func, state[:def_func] || &Base.default_def_func/1),
      send_config_func: Map.get(config, :send_config_func, state[:send_config_func] || &Base.default_send_config_func/1),
      strip_name: state.strip_name, # not to be updated
      animation_name: state.animation_name # not to be updated
    }
  end

  @impl GenServer
  @spec handle_cast({:config, config_t}, state_t) :: {:noreply, state_t}
  def handle_cast({:config, config}, state) do
    state = update_config(state, config)

    {:noreply, update_leds(state)}
  end

  @impl GenServer
  @spec terminate(reason, state :: state_t) :: :ok
  when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, %{
    strip_name: strip_name,
    animation_name: animation_name,
    type: type
  } = _state) do
    case type do
      :animation -> PubSub.unsubscribe(:fledex, "trigger")
      :static -> :ok # nothing to do, since we haven't been subscribed
    end
    LedsDriver.drop_namespace(strip_name, animation_name)
  end
end
