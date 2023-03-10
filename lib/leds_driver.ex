defmodule Fledex.LedsDriver do
  @behaviour GenServer
  use Fledex.Color.Types

  require Logger
  alias Fledex.LedStripDriver.Driver
  alias Fledex.LedStripDriver.LoggerDriver
  alias Fledex.Color.Utils

  @type t :: %{
    timer: %{
      disabled: boolean,
      counter: pos_integer,
      update_timeout: pos_integer,
      update_func: (t -> t),
      only_dirty_update: boolean,
      is_dirty: boolean,
      ref: reference
    },
    led_strip: %{
      merge_strategy: atom,
      driver_modules: module,
      config: map
    },
    namespaces: map
  }

  @default_update_timeout 50
  @default_driver_modules [LoggerDriver]

  #client code
  @spec start_link(map, atom | {:global, any} | {:via, atom, any}) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(init_arg, server_name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, init_arg, name: server_name)
  end

  @spec define_namespace(atom, atom) :: ({:ok, atom} | {:error, String.t})
  def define_namespace(namespace, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:define_namespace, namespace})
  end
  @spec drop_namespace(atom, atom) :: :ok
  def drop_namespace(namespace, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:drop_namespace, namespace})
  end
  @spec exist_namespace(atom, atom) :: boolean
  def exist_namespace(namespace, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:exist_namespace, namespace})
  end
  @spec set_leds(atom, list(pos_integer), atom) :: (:ok | {:error, String.t})
  def set_leds(namespace, leds, server_name \\ __MODULE__) do
    GenServer.call(server_name, {:set_leds, namespace, leds})
  end

  # server code
  @impl true
  @spec init(map) :: {:ok, t} | {:stop, String.t}
  def init(init_args) when is_map(init_args) do
    state = init_state(init_args)
    state = if (state[:timer][:disabled] == false), do: start_timer(state), else: state

    {:ok, state}
  end
  def init(_) do
    {:stop, "Init args need to be a map"}
  end

  @spec init_state(map) :: t
  def init_state(init_args) when is_map(init_args) do
    driver_modules = case init_args[:led_strip][:driver_modules] do
      nil ->
        #Logger.warn("No driver_modules defined/ #{inspect @default_driver_modules} will be used")
        @default_driver_modules
      driver_modules when not is_list(driver_modules) ->
        Logger.warn("driver_modules is not a list")
        [driver_modules]
      driver_modules ->
        driver_modules
    end
    only_dirty_update = if init_args[:timer][:only_dirty_update] == nil do
      false
    else
       init_args[:timer][:only_dirty_update]
    end
    is_dirty = if init_args[:timer][:is_dirty] == nil do
      false
    else
      init_args[:timer][:is_dirty]
    end
    state = %{
      timer: %{
        disabled: init_args[:timer][:disabled] || false,
        counter: init_args[:timer][:counter] || 0,
        update_timeout: init_args[:timer][:update_timeout] || @default_update_timeout,
        update_func: init_args[:timer][:update_func] || &transfer_data/1,
        only_dirty_update: only_dirty_update,
        is_dirty: is_dirty,
        ref: nil
      },
      led_strip: %{
        merge_strategy: init_args[:led_strip][:merge_strategy] || :avg,
        driver_modules: driver_modules,
        config: init_args[:led_strip][:config] || %{}
      },
      namespaces: init_args[:namespaces] || %{}
    }
    Driver.init(init_args, state)
  end

  @impl true
  @spec terminate(reason, state :: Fledex.LedDriver.t) :: :ok
  when reason: :normal | :shutdown | {:shutdown, term()} | term()
  def terminate(reason, state) do
    Driver.terminate(reason, state)
  end

  @spec start_timer(t) :: t
  defp start_timer(state) do
    update_timeout = state[:timer][:update_timeout]
    update_func = state[:timer][:update_func]

    ref = Process.send_after(self(), {:update_timeout, update_func}, update_timeout)
    state = update_in(state, [:timer, :ref], fn (_current_ref) -> ref end )

    state
  end

  @impl true
  @spec handle_call({:define_namespace, atom}, {pid, any}, t) :: {:reply, ({:ok, atom} | {:error, binary}), t}
  def handle_call({:define_namespace, name}, _from, %{namespaces: namespaces} = state) do
    state = put_in(state, [:timer, :is_dirty], true)
    case Map.has_key?(namespaces, name) do
      false ->  {:reply, {:ok, name}, %{state | namespaces: Map.put_new(namespaces, name, [])}}
      true -> {:reply, {:error, "namespace already exists"}, state}
    end
  end

  @impl true
  @spec handle_call({:drop_namespace, atom}, {pid, any}, t) :: {:reply, :ok, t}
  def handle_call({:drop_namespace, name}, _from, %{namespaces: namespaces} = state) do
    state = put_in(state, [:timer, :is_dirty], true)
    {:reply, :ok, %{state | namespaces: Map.drop(namespaces, [name])}}
  end

  @impl true
  @spec handle_call({:exist_namespace, atom}, {pid, any}, t) :: {:reply, boolean, t}
  def handle_call({:exist_namespace, name}, _from, %{namespaces: namespaces} = state) do
    exists = case Map.fetch(namespaces, name) do
      {:ok, _} -> true
      _ -> false
    end
    {:reply, exists, state}
  end

  @impl true
  @spec handle_call({:set_leds, atom, list(colorint)}, {pid, any}, t)
      :: {:reply, (:ok | {:error, String.t}), t}
  def handle_call({:set_leds, name, leds}, _from, %{namespaces: namespaces} = state) do
    state = put_in(state, [:timer, :is_dirty], true)
    case Map.has_key?(namespaces, name) do
      true ->  {:reply, :ok, %{state | namespaces: Map.put(namespaces, name, leds)}}
      false -> {:reply, {:error, "no such namespace, you need to define one first with :define_namespace"}, state}
    end
  end

  @impl true
  @spec handle_info({:update_timeout, (t -> t)}, t) :: {:noreply, t}
  def handle_info({:update_timeout, func}, state) do
    # here should now come some processing for now we just increase the counter and reschdule the timer
    state = update_in(state, [:timer, :counter], &(&1+1))
    state = start_timer(state)

    # Logger.info "calling #{inspect func}"
    state = func.(state)

    {:noreply, state}
  end

  @spec transfer_data(t) :: t
  def transfer_data(%{timer: %{is_dirty: is_dirty, only_dirty_updates: only_dirty_updates}} = state) when only_dirty_updates == true and is_dirty == false do
    # we shortcut if there is nothing to update and if we are allowed to shortcut
    state
  end
  def transfer_data(state) do
    # state = :telemetry.span(
    #   [:transfer_data],
    #   %{timer_counter: state.timer.counter},
    #   fn ->
        state = state.namespaces
          |> merge_namespaces(state.led_strip.merge_strategy)
          |> Driver.transfer(state)
          |> put_in([:timer,:is_dirty], false)
    #       {state, %{metadata: "done"}}
    #   end
    # )
    state
  end

  @spec merge_namespaces(map, atom) :: list(colorint)
  def merge_namespaces(namespaces, merge_strategy) do
    namespaces
      |> get_leds()
      |> merge_leds(merge_strategy)
  end
  @spec get_leds(map) :: list(list(colorint))
  def get_leds(namespaces) do
    Enum.reduce(namespaces, [], fn {_key, value}, acc ->
      acc ++ [value]
    end)
  end
  @spec merge_leds(list(list(colorint)), atom) :: list(colorint)
  def merge_leds(leds, merge_strategy) do
    leds = match_length(leds)
    Enum.zip_with(leds, fn elems ->
        merge_pixels(elems, merge_strategy)
    end)
  end

  @spec match_length(list(list(colorint))) :: list(list(colorint))
  def match_length(leds) when leds == nil, do: leds
  def match_length(leds) when length(leds) == 0, do: leds
  def match_length(leds) do
    max_length = Enum.reduce(leds, 0, fn(sequence, acc) -> max(acc, length(sequence)) end)
    Enum.map(leds, fn(sequence) -> extend(sequence, max_length - length(sequence)) end)
  end
  @spec extend(list(colorint), pos_integer) :: list(colorint)
  def extend(sequence, 0), do: sequence
  def extend(sequence, extra) do
    extra_length = Enum.reduce(1..extra, [], fn(_index, acc) -> acc ++ [0x000000] end)
    sequence ++ extra_length
  end
  @spec merge_pixels(list(colorint), atom) :: colorint
  def merge_pixels(elems, merge_strategy) do
    count = length(elems)
    elems
    |> Enum.map(fn elem -> Utils.split_into_subpixels(elem) end)
    |> Utils.add_subpixels()
    |> apply_merge_strategy(count, merge_strategy)
    |> Utils.combine_subpixels()
  end

  @spec apply_merge_strategy({pos_integer, pos_integer, pos_integer}, pos_integer, atom) :: rgb
  def apply_merge_strategy(rgb, count, merge_strategy) do
    case merge_strategy do
      :avg -> Utils.avg(rgb, count)
      :cap -> Utils.cap(rgb)
      _ -> raise "Unknown merge strategy"
    end
  end
end
