defmodule Fledex.LedAnimator do
  @moduledoc """
  The client often wants to run some animations. This can of course be done by repeatedly updating the `Leds` definitions and calling
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
   * The send config (even though we will have to implement that as a function too due to the handling of the index)

   Note: the time is not something that can be specified, since the animator will be triggered by
   `LedsDriver` in it's update frequency. Thus to implement some wait pattern, the trigger counter (or some
   other timer logic) should be used

   Both of them can be set by defining an appropriate function and setting and resetting a reference at will
  """
  @behaviour GenServer

  require Logger

  alias Fledex.Leds
  alias Fledex.LedsDriver
  alias Fledex.Utils.PubSub

  @type ledAnimatorConfig :: %{
      optional(:def_func) => ((map) -> Leds.t()),
      optional(:send_config_func) => ((map) -> map()),
      optional(:counter) => integer,
      optional(:timer_ref) => reference | nil,
      optional(:strip_name) => atom,
      optional(:animator_name) => atom
    }

  @type ledAnimatorState :: %{
    :triggers => map,
    :def_func => ((integer) -> Leds.t()),
    :send_config_func => ((integer) -> map()),
    :strip_name => atom,
    :animator_name => atom
  }
  ### client side
  @spec start_link(config :: ledAnimatorConfig, strip_name::atom, animator_name::atom) :: GenServer.on_start()
  def start_link(config, strip_name, animator_name) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, {config, strip_name, animator_name},
                    name: build_server_name(strip_name, animator_name))
  end

  defp build_server_name(strip_name, animator_name) do
    String.to_atom("#{strip_name}_#{animator_name}")
  end

  @spec config(atom, atom, ledAnimatorConfig) :: :ok
  def config(strip_name, animator_name, config) do
    GenServer.cast(build_server_name(strip_name, animator_name), {:config, config})
  end

  @spec shutdown(atom, atom) :: :ok
  def shutdown(strip_name, animator_name) do
    GenServer.stop(build_server_name(strip_name, animator_name), :normal)
  end

  ### server side
  @default_leds Leds.new(30)
  def default_def_func(_triggers) do
    @default_leds
  end
  def default_send_config_func(_triggers) do
    %{rotate_left: true}
  end

  @impl true
  @spec init({ledAnimatorConfig, atom, atom}) :: {:ok, ledAnimatorState, {:continue, :start_timer}}
  def init({init_args, strip_name, animator_name}) do
    state = %{
      triggers: %{},
      def_func: &default_def_func/1,
      send_config_func: &default_send_config_func/1,
      strip_name: strip_name,
      animator_name: animator_name
    }
    state = update_config(state, init_args)

    LedsDriver.define_namespace(state.animator_name, state.strip_name)

    {:ok, state, {:continue, :start_timer}}
  end

  @impl true
  @spec handle_continue(:start_timer, ledAnimatorState) :: {:noreply, ledAnimatorState}
  def handle_continue(:start_timer, state) do
    PubSub.subscribe(:fledex, "trigger")
    {:noreply, state}
  end

  @impl true
  @spec handle_info({:trigger, map}, ledAnimatorState) :: {:noreply, ledAnimatorState}
  def handle_info({:trigger, triggers}, %{
    strip_name: strip_name,
    animator_name: animator_name,
    def_func: def_func,
    send_config_func: send_config_func
  } = state) when is_map_key(triggers, strip_name) do
    # Logger.info("#{strip_name}, #{animator_name}")
    # we only want to trigger the led update if we have a trigger from the driver (=strip_name as key)
    # otherwise we collect the triggers. Now it's time to merge previously collected triggers in
    triggers = Map.merge(state.triggers, triggers)

    # we can get two different responses, with or without triggers, we make sure our result contains the triggers
    {leds, triggers} = def_func.(triggers) |> get_with_triggers(triggers)
    # independent on the configs say we want to ensure we use the correct namespace (animator_name)
    # and server_name (strip_name). Therefore we inject it
    leds = Leds.set_driver_info(leds, animator_name, strip_name)
    {config, triggers} = send_config_func.(triggers) |> get_with_triggers(triggers)
    try do
      Leds.send(leds, config)
    catch
      UndefinedFunctionError -> Logger.info("Function couldn't be found")
    end
    # Logger.info("trigger #{inspect triggers}")

    {:noreply, %{state | triggers: triggers}}
  end
  # the response can be with or without trigger, we ensure that it's always with a trigger, in the worst case
  # with the original triggers.
  def handle_info({:trigger, triggers}, state) do
    # if the trigger is not from the driver (=strip_name as key) we only want to collect
    # the triggers for when we want an update of the leds

    {:noreply, %{state | triggers: Map.merge(state.triggers, triggers)}}
  end

  defp get_with_triggers(response, orig_triggers) do
    case response do
      {leds, triggers} -> {leds, triggers}
      leds -> {leds, orig_triggers}
    end
  end

  @spec update_config(ledAnimatorState, ledAnimatorConfig) :: ledAnimatorState
  def update_config(state, config) do
    %{
      triggers: Map.merge(state.triggers, config[:triggers] || %{}),
      def_func: Map.get(config, :def_func, state.def_func),
      send_config_func: Map.get(config, :send_config_func, state.send_config_func),
      strip_name: state.strip_name,
      animator_name: state.animator_name
    }
  end

  @impl true
  @spec handle_cast({:config, ledAnimatorConfig}, ledAnimatorState) :: {:noreply, ledAnimatorState}
  def handle_cast({:config, config}, state) do
    state = update_config(state, config)

    {:noreply, state}
  end

  @impl true
  @spec terminate(reason, state :: ledAnimatorState) :: :ok
  when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(_reason, %{
    strip_name: strip_name,
    animator_name: animator_name
  } = _state) do
      LedsDriver.drop_namespace(animator_name, strip_name)
  end
end
