defmodule Fledex.LedsDriver do
  @moduledoc """
  This module defines a GenServer that manages the LED strip (be it a real one with the
  SpiDriver or a virtual one with e.g. the KinoDriver). Usually you only want to start
  one server, even though it is possible to start several.
  The LedsDriver will take several Leds definitions and merge them together to be displayed
  on a single LED strip
  The role the LedsDriver plays is similar to the one a window server  plays on a normal computer
  """
  use GenServer

  require Logger

  alias Fledex.Color.Correction
  alias Fledex.Color.Types
  alias Fledex.Color.Utils
  alias Fledex.LedStripDriver.Driver
  alias Fledex.LedStripDriver.NullDriver
  alias Fledex.Utils.PubSub

  @type timer_t :: %{
    disabled: boolean,
    counter: pos_integer,
    update_timeout: pos_integer,
    update_func: (state_t -> state_t),
    only_dirty_update: boolean,
    is_dirty: boolean,
    ref: reference | nil
  }
  @type state_t :: %{
    strip_name: atom,
    timer: timer_t,
    led_strip: Driver.driver_t,
    namespaces: map
  }

  @default_update_timeout 50
  @default_driver_modules [NullDriver]

  # client code
  @spec start_link(atom | {:global, any} | {:via, atom, any}, atom | map) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(strip_name \\ __MODULE__, config \\ :none)
  def start_link(strip_name, :none), do: start_link(strip_name, %{})
  def start_link(strip_name, :kino) do
    config = %{
      timer: %{only_dirty_update: true},
      led_strip: %{
        merge_strategy: :cap,
        driver_modules: [Fledex.LedStripDriver.KinoDriver],
        config: %{
          Fledex.LedStripDriver.KinoDriver => %{
            update_freq: 1,
            color_correction: Correction.no_color_correction()
          }
        }
      }
    }

    start_link(strip_name, config)
  end
  def start_link(strip_name, :spi) do
    config = %{
      timer: %{only_dirty_update: true},
      led_strip: %{
        merge_strategy: :cap,
        driver_modules: [Fledex.LedStripDriver.SpiDriver],
        config: %{
          Fledex.LedStripDriver.SpiDriver => %{
            color_correction: Correction.define_correction(
              Correction.Color.typical_smd5050(),
              Correction.Temperature.uncorrected_temperature()
            )
          }
        }
      }
    }

    start_link(strip_name, config)
  end
  def start_link(strip_name, init_args) when is_map(init_args) do
    # Logger.info(Exception.format_stacktrace())
    GenServer.start_link(__MODULE__, {init_args, strip_name}, name: strip_name)
  end

  @spec define_namespace(atom, atom) :: :ok | {:error, String.t()}
  def define_namespace(strip_name \\ __MODULE__, namespace) do
    # Logger.info("defining namespace: #{strip_name}-#{namespace}")
    GenServer.call(strip_name, {:define_namespace, namespace})
  end

  @spec drop_namespace(atom, atom) :: :ok
  def drop_namespace(strip_name \\ __MODULE__, namespace) do
    # Logger.info("dropping namespace: #{strip_name}-#{namespace}")
    GenServer.call(strip_name, {:drop_namespace, namespace})
  end

  @spec exist_namespace(atom, atom) :: boolean
  def exist_namespace(strip_name \\ __MODULE__, namespace) do
    GenServer.call(strip_name, {:exist_namespace, namespace})
  end

  @spec set_leds(atom, atom, list(pos_integer)) :: :ok | {:error, String.t()}
  def set_leds(strip_name \\ __MODULE__, namespace, leds) do
    GenServer.call(strip_name, {:set_leds, namespace, leds})
  end

  @spec change_config(atom, list(atom), any) :: {:ok, any}
  def change_config(strip_name \\ __MODULE__, config_path, value) do
    GenServer.call(strip_name, {:change_config, config_path, value})
  end
  @spec reinit_drivers(atom) :: :ok
  def reinit_drivers(strip_name \\ __MODULE__) do
    GenServer.call(strip_name, :reinit_drivers)
  end

  # server code
  @impl GenServer
  @spec init({map, atom}) :: {:ok, state_t}  | {:stop, String.t()}
  def init({init_args, strip_name}) when is_map(init_args) and is_atom(strip_name) do
    state = init_state(init_args, strip_name)
      |> init_driver()
      |> start_timer()

    {:ok, state}
  end
  def init(_na) do
    {:stop, "Init args need to be a map"}
  end
  @spec init_driver(state_t) :: state_t
  def init_driver(state) do
    %{state | led_strip: Driver.init(state.led_strip)}
  end
  @spec init_state(map, atom) :: state_t
  def init_state(init_args, strip_name) when is_map(init_args) and is_atom(strip_name) do
    %{
      strip_name: strip_name,
      timer: init_timer(init_args[:timer] || %{}),
      led_strip: init_led_strip(init_args[:led_strip] || %{}),
      namespaces: init_args[:namespaces] || %{}
    }
  end

  @spec init_led_strip(map) :: Driver.driver_t
  defp init_led_strip(init_args) do
    %{
      merge_strategy: init_args[:merge_strategy] || :avg,
      driver_modules: define_drivers(init_args[:driver_modules]),
      config: init_args[:config] || %{}
    }
  end

  @spec define_drivers(nil | module | [module]) :: [module]
  defp define_drivers(nil) do
    # Logger.warning("No driver_modules defined/ #{inspect @default_driver_modules} will be used")
    @default_driver_modules
  end
  defp define_drivers(driver_modules) when is_list(driver_modules) do
    driver_modules
  end
  defp define_drivers(driver_modules) do
    Logger.warning("driver_modules is not a list")
    [driver_modules]
  end

  @spec init_timer(map) :: timer_t
  defp init_timer(init_args) when is_map(init_args) do
    default = %{
      disabled: false,
      counter: 0,
      update_timeout: @default_update_timeout,
      update_func: (&transfer_data/1),
      only_dirty_update: false,
      is_dirty: false,
      ref: nil,
    }
    Map.merge(default, init_args)
  end

  @impl GenServer
  @spec terminate(reason, state_t) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(reason, state) do
    Driver.terminate(reason, state.led_strip)
  end

  @spec start_timer(state_t) :: state_t
  defp start_timer(%{timer: %{disabled: true}} = state), do: state
  defp start_timer(state) do
    update_timeout = state[:timer][:update_timeout]
    update_func = state[:timer][:update_func]

    ref = Process.send_after(self(), {:update_timeout, update_func}, update_timeout)
    state = update_in(state, [:timer, :ref], fn _current_ref -> ref end)

    state
  end

  @impl GenServer
  @spec handle_call({:define_namespace, atom}, {pid, any}, state_t) ::
          {:reply, :ok | {:error, binary}, state_t}
  def handle_call({:define_namespace, name}, _from, %{namespaces: namespaces} = state) do
    state = put_in(state, [:timer, :is_dirty], true)

    case Map.has_key?(namespaces, name) do
      false -> {:reply, :ok, %{state | namespaces: Map.put_new(namespaces, name, [])}}
      true -> {:reply, {:error, "namespace already exists"}, state}
    end
  end

  @impl GenServer
  @spec handle_call({:drop_namespace, atom}, GenServer.from, state_t) :: {:reply, :ok, state_t}
  def handle_call({:drop_namespace, name}, _from, %{namespaces: namespaces} = state) do
    state = put_in(state, [:timer, :is_dirty], true)
    {:reply, :ok, %{state | namespaces: Map.drop(namespaces, [name])}}
  end

  @impl GenServer
  @spec handle_call({:exist_namespace, atom}, GenServer.from, state_t) :: {:reply, boolean, state_t}
  def handle_call({:exist_namespace, name}, _from, %{namespaces: namespaces} = state) do
    exists =
      case Map.fetch(namespaces, name) do
        {:ok, _na} -> true
        _na -> false
      end

    {:reply, exists, state}
  end

  @impl GenServer
  @spec handle_call({:set_leds, atom, list(Types.colorint())}, {pid, any}, state_t) ::
          {:reply, :ok | {:error, String.t()}, state_t}
  def handle_call({:set_leds, name, leds}, _from, %{namespaces: namespaces} = state) do
    state = put_in(state, [:timer, :is_dirty], true)

    case Map.has_key?(namespaces, name) do
      true ->
        {:reply, :ok, %{state | namespaces: Map.put(namespaces, name, leds)}}

      false ->
        {:reply,
         {:error, "no such namespace, you need to define one first with :define_namespace"},
         state}
    end
  end

  @impl GenServer
  @spec handle_call({:change_config, list(atom), any}, {pid, any}, state_t) :: {:reply, {:ok, any}, state_t}
  def handle_call({:change_config, config_path, value}, _from, state) do
    previous_value = get_in(state, config_path)
    state = put_in(state, config_path, value)
    {:reply, {:ok, previous_value}, state}
  end

  @impl GenServer
  @spec handle_call(:reinit_drivers, {pid, any}, state_t) :: {:reply, :ok, state_t}
  def handle_call(:reinit_drivers, _from, state) do
    {:reply, :ok, %{state | led_strip: Driver.reinit(state.led_strip)}}
  end

  @impl GenServer
  @spec handle_info({:update_timeout, (state_t -> state_t)}, state_t) :: {:noreply, state_t}
  def handle_info({:update_timeout, func}, state) do
    state = update_in(state, [:timer, :counter], &(&1 + 1))
      |> start_timer()
      |> func.()

    PubSub.broadcast(:fledex, "trigger", {:trigger, Map.put(%{}, state.strip_name , state.timer.counter)})
    {:noreply, state}
  end

  @spec transfer_data(state_t) :: state_t
  def transfer_data(
        %{timer: %{is_dirty: is_dirty, only_dirty_updates: only_dirty_updates}} = state
      )
      when only_dirty_updates == true and is_dirty == false do
    # we shortcut if there is nothing to update and if we are allowed to shortcut
    state
  end
  def transfer_data(state) do
    # state = :telemetry.span(
    #   [:transfer_data],
    #   %{timer_counter: state.timer.counter},
    #   fn ->
    led_strip =
      state.namespaces
      |> merge_namespaces(state.led_strip.merge_strategy)
      |> Driver.transfer(state.timer.counter, state.led_strip)

    %{state | led_strip: led_strip}
      |> put_in([:timer, :is_dirty], false)

    #       {state, %{metadata: "done"}}
    #   end
    # )
  end

  @spec merge_namespaces(map, atom) :: list(Types.colorint())
  def merge_namespaces(namespaces, merge_strategy) do
    namespaces
    |> get_leds()
    |> merge_leds(merge_strategy)
  end

  @spec get_leds(map) :: list(list(Types.colorint()))
  def get_leds(namespaces) do
    Enum.reduce(namespaces, [], fn {_key, value}, acc ->
      acc ++ [value]
    end)
  end

  @spec merge_leds(list(list(Types.colorint())), atom) :: list(Types.colorint())
  def merge_leds(leds, merge_strategy) do
    leds = match_length(leds)

    Enum.zip_with(leds, fn elems ->
      merge_pixels(elems, merge_strategy)
    end)
  end

  @spec match_length(list(list(Types.colorint()))) :: list(list(Types.colorint()))
  def match_length(leds) when leds == [], do: leds
  def match_length(leds) do
    max_length = Enum.reduce(leds, 0, fn sequence, acc -> max(acc, length(sequence)) end)
    Enum.map(leds, fn sequence -> extend(sequence, max_length - length(sequence)) end)
  end

  @spec extend(list(Types.colorint()), pos_integer) :: list(Types.colorint())
  def extend(sequence, 0), do: sequence

  def extend(sequence, extra) do
    extra_length = Enum.reduce(1..extra, [], fn _index, acc -> acc ++ [0x000000] end)
    sequence ++ extra_length
  end

  @spec merge_pixels(list(Types.colorint()), atom) :: Types.colorint()
  def merge_pixels(elems, merge_strategy) do
    elems
    |> Enum.map(fn elem -> Utils.split_into_subpixels(elem) end)
    |> apply_merge_strategy(merge_strategy)
    |> Utils.to_colorint()
  end

  @spec apply_merge_strategy(list(Types.colorint()), atom) :: Types.rgb()
  def apply_merge_strategy(rgb, merge_strategy) do
    case merge_strategy do
      :avg -> Utils.avg(rgb)
      :cap -> Utils.cap(rgb)
      na -> raise ArgumentError, message: "Unknown merge strategy #{na}"
    end
  end
end
