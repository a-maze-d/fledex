defmodule LedsDriver do
  @behaviour GenServer
  import Bitwise

  @default_update_timeout 50

  #client code
  def start_link(init_arg, server_name \\ :default) do
    GenServer.start_link(__MODULE__, init_arg, name: server_name)
  end

  def define_leds(leds_name, server_name \\ :default) do
    GenServer.call(server_name, {:define_leds, leds_name})
  end

  # server code
  @impl true
  def init(init_args) do
    state = init_state(init_args)
    state = if (state[:timer][:disabled] == false), do: start_timer(state), else: state

    {:ok, state}
  end

  def init_state(init_args) do
    state = %{
      timer: %{
        disabled: init_args[:timer][:disabled] || false,
        counter: init_args[:timer][:counter] || 0,
        update_timeout: init_args[:timer][:update_timeout] || @default_update_timeout,
        update_func: init_args[:timer][:update_func] || &transfer_data/1,
        ref: nil
      },
      led_strip: %{
        driver_module: init_args[:led_strip][:driver_module] || LedStripDrivers.LoggerDriver
      }
    }
    init_led_strip_driver(init_args, state)
  end

  def init_led_strip_driver(init_args, state) do
    module = state.led_strip.driver_module
    module.init(init_args, state)
  end

  def termination(reason, state) do
    module = state.led_strip.driver_module
    module.terminate(reason, state)
  end

  defp start_timer(state) do
    update_timeout = state[:timer][:update_timeout]
    update_func = state[:timer][:func]

    ref = Process.send_after(self(), {:update_timeout, update_func}, update_timeout)
    state = update_in(state, [:timer, :ref], fn (_current_ref) -> ref end )

    state
  end

  @impl true
  def handle_call({:define_leds, name}, _from, %{namespaces: namespaces} = state) do
    case Map.has_key?(namespaces, name) do
      false ->  {:reply, {:ok, name}, %{state | namespaces: add_namespace(namespaces, name)}}
      true -> {:reply, {:error, "namespace already exists"}, state}
    end
  end

  @impl true
  def handle_call({:set_leds, leds, name}, _from, %{namespaces: namespaces} = state) do
    case Map.has_key?(namespaces, name) do
      true ->  {:reply, :ok, %{state | namespace: set_leds_in_namespace(namespaces, name, leds)}}
      false -> {:reply, {:error, "no such namespace, you need to define one first with :define_leds"}, state}
    end
  end

  @impl true
  def handle_info({:update_timeout, func}, state) do
    # here should now come some processing for now we just increase the counter and reschdule the timer
    state = update_in(state, [:timer, :counter], &(&1+1))
    state = start_timer(state)

    func.(state)

    {:noreply, state}
  end

  def transfer_data(state) do
    state.namespaces
      |> merge_namespaces()
      |> to_binary()
      |> send_to_strip(state)
  end

  defp avg_and_combine({r,g,b}, count) do
    r = Kernel.trunc(r/count)
    g = Kernel.trunc(g/count)
    b = Kernel.trunc(b/count)
    (r<<<16) + (g<<<8) + b
  end

  defp merge_namespaces([]), do: []
  defp merge_namespaces(namespaces) do
    namespaces
      |> Enum.reduce([], fn {_key, value}, acc -> acc ++ value end)
      |> Enum.zip_with(fn elems ->
        count = length(elems)
        Enum.map(elems, fn elem ->
          r = elem &&& 0xFF0000 >>> 16
          g = elem &&& 0x00FF00 >>> 8
          b = elem &&& 0x0000FF
          {r, g, b}
        end)
        |> Enum.reduce({0,0,0}, fn {r,g,b}, {accr, accg, accb} -> {r+accr, g+accg, b+accb} end)
        |> avg_and_combine(count)
      end)
  end

  defp to_binary(leds) do
    Enum.reduce(leds, <<>>, fn led, acc -> acc <> <<led>> end)
  end

  defp send_to_strip(binary, state) do
    module = state.led_strip.driver_module
    module.transfer(binary, state)
  end

  defp add_namespace(namespaces, name) do
    Map.put_new(namespaces, name, nil)
  end

  defp set_leds_in_namespace(namespaces, name, leds) do
    Map.put(namespaces, name, [leds])
  end
end
