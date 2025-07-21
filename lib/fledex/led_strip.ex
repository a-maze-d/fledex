# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.LedStrip do
  @moduledoc """
  This module defines a GenServer that manages the LED strip (be it a real one with the
  `Fledex.Driver.Impl.Spi` or a virtual one with e.g. the `Fledex.Driver.Impl.Kino`).

  You would start an `LedStrip` for every led strip you have.

  The `Fledex.LedStrip` will take several `Fledex.Leds` definitions and merge them
  together to be displayed on a single LED strip.

  The role the LedStrip plays is similar to the one a window server  plays on a normal
  computer, except that a window server would manage several screens, whereas here each
  LED strip would get its own.

  Note: In general you shouldn't require to start an LedStrip directly, but you should
  use the `Fledex DSL`. In order to start an `LedStrip` a Registry (with name as provided by
  `Fledex.Subscription.Utils.worker_registry/0`) is required.
  """
  use GenServer

  require Logger

  alias Fledex.Color
  alias Fledex.Color.Conversion.CalcUtils
  alias Fledex.Color.Types
  alias Fledex.Driver.Impl.Null
  alias Fledex.Driver.Manager
  alias Fledex.Effect.Rotation
  alias Fledex.Supervisor.Utils
  alias Fledex.Utils.PubSub

  @type start_link_response :: :ignore | {:error, any} | {:ok, pid}
  @type drivers_config_t :: module | Manager.driver_t() | Manager.drivers_t()
  @typep timer_t :: %{
           disabled: boolean,
           counter: pos_integer,
           update_timeout: pos_integer,
           update_func: (state_t -> state_t),
           only_dirty_update: boolean,
           is_dirty: boolean,
           ref: reference | nil
         }
  @typep config_t :: %{
           group_leader: pid | nil,
           merge_strategy: atom,
           timer: timer_t
         }

  @typep state_t :: %{
           strip_name: atom,
           config: config_t,
           drivers: Manager.drivers_t(),
           namespaces: map
         }

  @default_update_timeout 50
  @config_mappings %{
    timer_disabled: [:timer, :disabled],
    timer_counter: [:timer, :counter],
    timer_update_timeout: [:timer, :update_timeout],
    timer_update_func: [:timer, :update_func],
    timer_only_dirty_update: [:timer, :only_dirty_update],
    timer_is_dirty: [:timer, :is_dirty],
    merge_strategy: [:merge_strategy],
    group_leader: [:group_leader]
  }

  # client code
  @spec child_spec({atom, drivers_config_t(), keyword}) :: Supervisor.child_spec()
  def child_spec({strip_name, drivers, global_onfig}) do
    %{
      id: strip_name,
      start: {__MODULE__, :start_link, [strip_name, drivers, global_onfig]}
    }
  end

  @doc """
  This starts the server controlling a specfic led strip. It is possible
  to install several drivers at the same time, so different hardware gets the same data
  at the same time (similar to mirroring a screen). If you want to send different
  data to different strips, you should start several instances of this server

  Because we can have several drivers (even though that is rather the exception)
  the confirgation is split up into several parts (not all of them need to be present):
  * The name of the strip (mandatory)
  * The global configuration of the strip (optional, defaults will be used if not specified)
  * A driver module (that also provides a default set of configs)
  * A list of detailed configs that are overlayed over the defaults. This allows
    for example to reuse the `Fledex.Driver.Impl.Spi` defaults, but change for example
    to a different spi device by setting `:dev` to `spidev0.1`

  Here some examples (with aliased module names) how you can start the server:
  * Without real driver: `start_link(:name)`
  * With real driver: `start_link(:name, Spi)`
  * With some global config overlay and real driver: `start_link(:name, Spi, timer_only_dirty_update: true)`
  * With real driver and some driver overlay: `start_link(:name, {Spi, dev: "spidev0.1"})`
  * With several drivers: `start_link(:name, [{Spu, []}, {Spi, dev: "spidev0.1"}])`
  * With several drivers and global config: `start_link(:name, [{Spi, []}, {Spi, dev: "spidev0.1"}], timer_only_dirty_update: true)`
  """
  @spec start_link(atom, drivers_config_t, keyword) ::
          GenServer.on_start()
  def start_link(strip_name, driver \\ Null, global_config \\ [])

  def start_link(strip_name, driver, global_config)
      when is_atom(driver) and is_list(global_config) do
    start_link(strip_name, {driver, []}, global_config)
  end

  def start_link(strip_name, {_driver, _driver_config} = driver, global_config)
      when is_list(global_config) do
    start_link(strip_name, [driver], global_config)
  end

  def start_link(strip_name, drivers, global_config)
      when is_list(drivers) and is_list(global_config) do
    drivers = Manager.remove_invalid_drivers(drivers)

    # case whereis(strip_name) do
    #   nil ->
    GenServer.start_link(
      __MODULE__,
      {strip_name, drivers, global_config},
      name: Utils.via_tuple(strip_name, :led_strip, :strip)
    )

    #   pid ->
    #     {:ok, pid}
    # end
  end

  def start_link(strip_name, drivers, global_config) do
    {:error,
     "Unexpected arguments #{inspect(strip_name)}, #{inspect(drivers)}, #{inspect(global_config)}"}
  end

  @doc """
  Define a new namespace
  """
  @spec define_namespace(atom, atom) :: :ok | {:error, String.t()}
  def define_namespace(strip_name, namespace) do
    # Logger.info("defining namespace: #{strip_name}-#{namespace}")
    GenServer.call(
      Utils.via_tuple(strip_name, :led_strip, :strip),
      {:define_namespace, namespace}
    )
  end

  @doc """
  Drop a previously defined namespace.
  """
  @spec drop_namespace(atom, atom) :: :ok
  def drop_namespace(strip_name, namespace) do
    GenServer.call(Utils.via_tuple(strip_name, :led_strip, :strip), {:drop_namespace, namespace})
  end

  @doc """
  Checks whether the specified namespace already exists
  """
  @spec exist_namespace(atom, atom) :: boolean
  def exist_namespace(strip_name, namespace) do
    GenServer.call(Utils.via_tuple(strip_name, :led_strip, :strip), {:exist_namespace, namespace})
  end

  @doc """
  Sets the leds in a specific strip and namespace.

  The `count` should correspond to the length of the leds list and will be
  calculated if not provided (but often this information is already available
  and therefore can be provided)

  Note: repeated calls of this function will result in previously set leds
  will be overwritten. We are passing a list of leds which means every led
  will be rewritten, except if we define a 'shorter" led sequence. In that
  case some leds might retain their previously set value.
  """
  @spec set_leds(atom, atom, list(pos_integer), non_neg_integer() | nil) ::
          :ok | {:error, String.t()}
  def set_leds(strip_name, namespace, leds, count \\ nil)
      when (count == nil or (is_integer(count) and count >= 0)) and is_atom(strip_name) and
             is_atom(namespace) do
    GenServer.call(
      Utils.via_tuple(strip_name, :led_strip, :strip),
      {:set_leds, namespace, leds, count}
    )
  end

  @doc """
  Similar to `set_leds/4` but allows to specify some options to rotate
  the leds.

  The recognized options are:
  * `:offset`: The amount to rotate
  * `:rotate_left`: whether we want to rotate to the left (or the right).
  The default is `true`
  """
  @spec set_leds_with_rotation(atom, atom, list(pos_integer), non_neg_integer() | nil, keyword) ::
          :ok | {:error, String.t()}
  def set_leds_with_rotation(strip_name, namespace, leds, count \\ nil, opts)
      when (count == nil or (is_integer(count) and count >= 0)) and is_atom(strip_name) and
             is_atom(namespace) do
    count = count || length(leds)
    offset = get_offset(opts)
    rotate_left = get_rotation_left(opts)
    offset = wrap_offset(offset, count)

    vals = Rotation.rotate(leds, count, offset, rotate_left)
    set_leds(strip_name, namespace, vals, count)
  end

  @doc """
  Change some aspect of a configuration for a specific strip. The configuration
  will be updated and the old values will be returned.
  """
  @spec change_config(atom, keyword) :: {:ok, [keyword]}
  def change_config(strip_name, global_config) do
    GenServer.call(
      Utils.via_tuple(strip_name, :led_strip, :strip),
      {:change_config, global_config}
    )
  end

  @doc """
  In some circumstances it might be necessary to reinitialize the led_strip
  (including the drivers). Most of the time you don't need to call this.
  If you do, you will surely know about it :)
  """
  @spec reinit(atom, drivers_config_t, keyword) :: :ok
  def reinit(strip_name, driver, strip_config) when is_atom(driver) do
    reinit(strip_name, {driver, []}, strip_config)
  end

  def reinit(strip_name, {_driver_module, _driver_config} = driver, strip_config) do
    reinit(strip_name, [driver], strip_config)
  end

  def reinit(strip_name, drivers, strip_config) do
    GenServer.call(
      Utils.via_tuple(strip_name, :led_strip, :strip),
      {:reinit, drivers, strip_config}
    )

    :ok
  end

  # MARK:server side
  @impl GenServer
  @spec init({atom, list({module, keyword}), keyword}) :: {:ok, state_t} | {:stop, String.t()}
  def init({strip_name, drivers, global_config})
      when is_atom(strip_name) and is_list(drivers) and is_list(global_config) do
    Logger.debug("starting led_strip: #{strip_name}", %{
      strip_name: strip_name,
      drivers: drivers,
      global_config: global_config
    })

    # make sure we call the terminate function whenever possible
    Process.flag(:trap_exit, true)

    {
      :ok,
      init_state(strip_name, drivers, global_config)
      |> start_timer()
    }
  end

  def init(_na) do
    {:stop, "Init args need to be a 3 element tuple with name, drivers, global config"}
  end

  @impl GenServer
  @spec terminate(reason, state_t) :: :ok
        when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(reason, %{strip_name: strip_name, drivers: drivers} = _state) do
    Logger.debug("shutting down led_strip: #{strip_name}", %{strip_name: strip_name})
    Manager.terminate(reason, drivers)
  end

  @impl GenServer
  @spec handle_call({:define_namespace, atom}, {pid, any}, state_t) ::
          {:reply, :ok | {:error, binary}, state_t}
  def handle_call({:define_namespace, name}, _from, %{namespaces: namespaces} = state) do
    state = put_in(state, [:config, :timer, :is_dirty], true)

    case Map.has_key?(namespaces, name) do
      false -> {:reply, :ok, %{state | namespaces: Map.put_new(namespaces, name, [])}}
      true -> {:reply, {:error, "namespace already exists"}, state}
    end
  end

  @impl GenServer
  @spec handle_call({:drop_namespace, atom}, GenServer.from(), state_t) :: {:reply, :ok, state_t}
  def handle_call({:drop_namespace, name}, _from, %{namespaces: namespaces} = state) do
    state = put_in(state, [:config, :timer, :is_dirty], true)
    {:reply, :ok, %{state | namespaces: Map.delete(namespaces, name)}}
  end

  @impl GenServer
  @spec handle_call({:exist_namespace, atom}, GenServer.from(), state_t) ::
          {:reply, boolean, state_t}
  def handle_call({:exist_namespace, name}, _from, %{namespaces: namespaces} = state) do
    exists =
      case Map.fetch(namespaces, name) do
        {:ok, _na} -> true
        _na -> false
      end

    {:reply, exists, state}
  end

  @impl GenServer
  @spec handle_call({:change_config, keyword}, {pid, any}, state_t) :: {:ok, keyword}
  def handle_call({:change_config, global_config}, _from, state) do
    {new_config, rets} = update_config(state.config, global_config)
    {:reply, {:ok, rets}, %{state | config: new_config}}
  end

  @impl GenServer
  @spec handle_call(
          {:set_leds, atom, list(Types.colorint()), non_neg_integer() | nil},
          {pid, any},
          state_t
        ) ::
          {:reply, :ok | {:error, String.t()}, state_t}
  def handle_call({:set_leds, name, leds, _count}, _from, %{namespaces: namespaces} = state) do
    state = put_in(state, [:config, :timer, :is_dirty], true)

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
  @spec handle_call({:reinit, Manager.drivers_t(), keyword}, {pid, any}, state_t) ::
          {:reply, :ok, state_t}
  def handle_call({:reinit, drivers, config}, _from, state) do
    {updated_config, _rets} = update_config(state.config, config)
    updated_drivers = Manager.reinit(state.drivers, drivers, updated_config)

    {:reply, :ok,
     %{
       state
       | config: updated_config,
         drivers: updated_drivers
     }}
  end

  @impl GenServer
  @spec handle_info({:update_timeout, (state_t -> state_t)}, state_t) :: {:noreply, state_t}
  def handle_info({:update_timeout, func}, state) do
    state =
      update_in(state, [:config, :timer, :counter], &(&1 + 1))
      |> start_timer()
      |> func.()

    _ignore_response =
      PubSub.broadcast_trigger(Map.put(%{}, state.strip_name, state.config.timer.counter))

    {:noreply, state}
  end

  ### MARK: public helper functions
  @doc false
  @spec init_state(atom, Manager.drivers_t(), keyword) :: state_t
  def init_state(strip_name, drivers, global_config)
      when is_atom(strip_name) and
             is_list(drivers) and
             is_list(global_config) do
    config = Keyword.delete(global_config, :namespaces)
    config = init_config(config)

    %{
      strip_name: strip_name,
      config: config,
      drivers: Manager.init_drivers(drivers, config),
      # led_strip: Manager.init_config(init_args[:led_strip] || %{}),
      namespaces: Keyword.get(global_config, :namespaces, %{})
    }
  end

  @doc false
  @spec transfer_data(state_t) :: state_t
  def transfer_data(
        %{config: %{timer: %{is_dirty: is_dirty, only_dirty_updates: only_dirty_updates}}} = state
      )
      when only_dirty_updates == true and is_dirty == false do
    # we shortcut if there is nothing to update and if we are allowed to shortcut
    state
  end

  def transfer_data(state) do
    # state = :telemetry.span(
    #   [:transfer_data],
    #   %{timer_counter: state.config.timer.counter},
    #   fn ->
    drivers =
      state.namespaces
      |> merge_namespaces(state.config.merge_strategy)
      |> Manager.transfer(state.config.timer.counter, state.drivers)

    %{state | drivers: drivers}
    |> put_in([:config, :timer, :is_dirty], false)

    #       {state, %{metadata: "done"}}
    #   end
    # )
  end

  @doc false
  @spec merge_namespaces(map, atom) :: list(Types.colorint())
  def merge_namespaces(namespaces, merge_strategy) do
    namespaces
    |> get_leds()
    |> merge_leds(merge_strategy)
  end

  @doc false
  @spec get_leds(map) :: list(list(Types.colorint()))
  def get_leds(namespaces) do
    Enum.reduce(namespaces, [], fn {_key, value}, acc ->
      acc ++ [value]
    end)
  end

  @doc false
  @spec merge_leds(list(list(Types.colorint())), atom) :: list(Types.colorint())
  def merge_leds(leds, merge_strategy) do
    leds = match_length(leds)

    Enum.zip_with(leds, fn elems ->
      merge_pixels(elems, merge_strategy)
    end)
  end

  @doc false
  @spec merge_pixels(list(Types.colorint()), atom) :: Types.colorint()
  def merge_pixels(elems, merge_strategy) do
    elems
    |> Enum.map(fn elem -> Color.to_rgb(elem) end)
    |> apply_merge_strategy(merge_strategy)
    |> Color.to_colorint()
  end

  # MARK: private helper functions
  @spec get_offset(keyword) :: non_neg_integer()
  defp get_offset(opts) do
    case Keyword.get(opts, :offset, 0) do
      x when is_integer(x) and x < 0 -> 0
      x when is_integer(x) -> x
      _other -> 0
    end
  end

  @spec get_rotation_left(keyword) :: boolean
  defp get_rotation_left(opts) do
    case Keyword.get(opts, :rotate_left, true) do
      x when is_boolean(x) -> x
      _other -> true
    end
  end

  @spec wrap_offset(offset :: non_neg_integer(), count :: non_neg_integer()) :: non_neg_integer()
  defp wrap_offset(_offset, 0), do: 0

  defp wrap_offset(offset, count) do
    rem(offset, count)
  end

  @spec init_config(keyword) :: config_t
  defp init_config(updates) do
    base = %{
      group_leader: nil,
      merge_strategy: :cap,
      timer: %{
        disabled: false,
        counter: 0,
        update_timeout: @default_update_timeout,
        update_func: &transfer_data/1,
        only_dirty_update: false,
        is_dirty: false,
        ref: nil
      }
    }

    {config, _rets} = update_config(base, updates)
    config
  end

  @spec update_config(base :: map, updates :: keyword) :: {map, keyword}
  defp update_config(base, updates) do
    Enum.reduce(updates, {base, []}, fn {key, value}, {config, rets} ->
      case key do
        key when is_map_key(@config_mappings, key) ->
          path = @config_mappings[key]
          old_value = get_in(config, path)
          {put_in(config, path, value), Keyword.put(rets, key, old_value)}

        key ->
          Logger.warning(
            "Unknown config key (#{inspect(key)} with value #{inspect(value)}) was specified\n#{Exception.format_stacktrace()}"
          )

          {config, rets}
      end
    end)
  end

  @spec start_timer(state_t) :: state_t
  defp start_timer(%{config: %{timer: %{disabled: true}}} = state), do: state

  defp start_timer(state) do
    update_timeout = state.config.timer.update_timeout
    update_func = state.config.timer.update_func

    ref = Process.send_after(self(), {:update_timeout, update_func}, update_timeout)
    state = update_in(state, [:config, :timer, :ref], fn _current_ref -> ref end)

    state
  end

  @spec match_length(list(list(Types.colorint()))) :: list(list(Types.colorint()))
  defp match_length(leds) when leds == [], do: leds

  defp match_length(leds) do
    max_length = Enum.reduce(leds, 0, fn sequence, acc -> max(acc, length(sequence)) end)
    Enum.map(leds, fn sequence -> extend(sequence, max_length - length(sequence)) end)
  end

  @spec extend(list(Types.colorint()), pos_integer) :: list(Types.colorint())
  defp extend(sequence, 0), do: sequence

  defp extend(sequence, extra) do
    extra_length = Enum.reduce(1..extra, [], fn _index, acc -> acc ++ [0x000000] end)
    sequence ++ extra_length
  end

  @spec apply_merge_strategy(list(Types.colorint()), atom) :: Types.rgb()
  defp apply_merge_strategy(rgb, :avg) do
    CalcUtils.avg(rgb)
  end

  defp apply_merge_strategy(rgb, :cap) do
    CalcUtils.cap(rgb)
  end

  defp apply_merge_strategy(_rgb, merge_strategy) do
    raise ArgumentError, message: "Unknown merge strategy #{inspect(merge_strategy)}"
  end
end
