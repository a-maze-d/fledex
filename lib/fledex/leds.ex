defmodule Fledex.Leds do
  require Logger

  import Bitwise

  alias Fledex.Color.Functions
  alias Fledex.Color.Names
  alias Fledex.Color.Types
  alias Fledex.Color.Utils
  alias Fledex.Leds
  alias Fledex.LedsDriver

  @enforce_keys [:count, :leds, :opts]
  defstruct count: 0, leds: %{}, opts: %{}, meta: %{index: 1} #, fill: :none
  @type t :: %__MODULE__{
    count: integer,
    leds: map,
    opts: map,
    meta: map
  }

  # @spec new() :: t
  # def new do
  #   new(0)
  # end
  # @spec new(integer) :: t
  # def new(count) do
  #   new(count, %{server_name: nil, namespace: nil})
  # end
  # @spec new(integer, map) :: t
  # def new(count, opts) do
  #   new(count, %{}, opts)
  # end
  # @spec new(integer, map, map) :: t
  # def new(count, leds, opts) do
  #   new(count, leds, opts, %{index: 1})
  # end
  # @spec new(integer, map, map, map) :: t
  # def new(count, leds, opts, meta) do
  #   %__MODULE__{
  #     count: count,
  #     leds: leds,
  #     opts: opts,
  #     meta: meta
  #   }
  # end
  @spec leds() :: t
  def leds do
    leds(0)
  end
  @spec leds(integer) :: t
  def leds(count) do
    leds(count, %{server_name: nil, namespace: nil})
  end
  @spec leds(integer, map) :: t
  def leds(count, opts) do
    leds(count, %{}, opts)
  end
  @spec leds(integer, map, map) :: t
  def leds(count, leds, opts) do
    leds(count, leds, opts, %{index: 1})
  end
  @spec leds(integer, map, map, map) :: t
  def leds(count, leds, opts, meta) do
    %__MODULE__{
      count: count,
      leds: leds,
      opts: opts,
      meta: meta
    }
  end

  @spec set_driver_info(t, namespace :: atom, server_name :: atom) :: t
  def set_driver_info(%{opts: opts} = leds, namespace, server_name \\  Fledex.LedsDriver) do
    opts = %{opts | server_name: server_name, namespace: namespace}
    %__MODULE__{leds | opts: opts}
  end

  @spec rainbow(t, map) :: t
  def rainbow(%Leds{} = leds, opts \\ %{}) do
    num_leds = Map.get(opts, :num_leds, leds.count)
    reversed = Map.get(opts, :reversed, false)
    offset = Map.get(opts, :offset, 0)
    initial_hue = Map.get(opts, :initial_hue, 0)

    led_values = Functions.create_rainbow_circular_rgb(num_leds, initial_hue, reversed)
      |> convert_to_leds_structure(offset)

    put_in(leds.leds, Map.merge(leds.leds, led_values))
  end

  @spec convert_to_leds_structure(list(Types.rgb), integer) :: map
  def convert_to_leds_structure(rgbs, offset \\ 0) do
    offset_oneindex = offset + 1
    Enum.zip_with(offset_oneindex..(offset_oneindex + length(rgbs)), rgbs, fn(index, {r, g, b}) ->
      {index, (r <<< 16) + (g <<< 8) + b}
    end) |>  Map.new
  end

  def gradient(leds, start_color, end_color, opts \\ []) do
    num_leds = opts[:num_leds] || leds.count
    offset = opts[:offset] || 0

    start_color = Utils.convert_to_subpixels(start_color)
    end_color = Utils.convert_to_subpixels(end_color)

    led_values = Functions.create_gradient_rgb(num_leds, start_color, end_color)
      |> convert_to_leds_structure(offset)

    put_in(leds.leds, Map.merge(leds.leds, led_values))
  end

  @spec repeat(t, integer) :: t
  def repeat(
    %__MODULE__{
      count: count,
      leds: leds,
      opts: opts,
      meta: meta
    },
    amount
  ) when amount > 1 do
    index = meta[:index]  || 1
    new_index = (amount - 1) * count + index
    new_count = count * amount
    new_leds = Enum.reduce(2..amount, leds, fn round, acc ->
      Map.merge(acc, remap_leds(leds, count * (round - 1) + 1))
    end)
    __MODULE__.leds(new_count, new_leds, opts, %{meta | index: new_index})
  end

  @spec light(t, (Types.colorint | t | atom)) :: t
  def light(leds, rgb) do
    do_update(leds, rgb)
  end
 @doc """
  offset is 1 indexed. Offset needs to be > 0 if it's bigger than the count
  then the led will be stored, but ignored
  """
  @spec light(t, (Types.colorint | t | atom), pos_integer) :: t
  def light(leds, led, offset) when offset > 0 do
    do_update(leds, led, offset)
  end
  def light(_leds, _led, offset) do
   raise ArgumentError, message: "the offset needs to be > 0 (found: #{offset})"
  end
  @spec light(t, (Types.colorint | t | atom), pos_integer, pos_integer) :: t
  def light(leds, led, offset, repeat) do
    led = case led do
      led when is_integer(led) -> __MODULE__.leds(1) |> __MODULE__.light(led)
      led when is_atom(led) -> __MODULE__.leds(1) |> __MODULE__.light(led)
      led when is_struct(led) -> led
    end
    led = led |> __MODULE__.repeat(repeat)
    __MODULE__.light(leds, led, offset)
  end

  @spec do_update(t, (Types.colorint | Types.rgb | atom)) :: t
  defp do_update(%__MODULE__{meta: meta} = leds, rgb) do
    index = meta[:index]  || 1
    index = if index < 1, do: 1, else: index
    do_update(leds, rgb, index)
  end

  @spec do_update(t, Types.colorint, pos_integer) :: t
  defp do_update(
    %__MODULE__{count: count, leds: leds, opts: opts, meta: meta},
    rgb,
    offset
  ) when is_integer(rgb) do
    __MODULE__.leds(count, Map.put(leds, offset, rgb), opts, %{meta | index: offset + 1})
  end
  @spec do_update(t, t, pos_integer) :: t
  defp do_update(
    %__MODULE__{count: count1, leds: leds1, opts: opts1, meta: meta1},
    %__MODULE__{count: count2, leds: leds2},
    offset
  ) do
    # remap the indicies (1 indexed)
    remapped_new_leds = remap_leds(leds2, offset)
    leds = Map.merge(leds1, remapped_new_leds)
    __MODULE__.leds(count1, leds, opts1, %{meta1 | index: offset + count2})
  end
  @spec do_update(t, atom, pos_integer) :: t
  defp do_update(leds, atom, offset) when is_atom(atom) do
    color_int = apply(Names, atom, [:hex])
    do_update(leds, color_int, offset)
  end
  defp do_update(leds, led, offset) do
    raise ArgumentError, message: "unknown data #{inspect leds}, #{inspect led}, #{inspect offset}"
  end

  defp remap_leds(leds, offset) do
    Map.new(Enum.map(leds, fn {key, value} ->
      index = offset + key - 1
      {index, value}
    end))
  end

  @spec to_binary(t) :: binary
  def to_binary(%__MODULE__{count: count, leds: _leds, opts: _opts, meta: _meta} = leds) do
    Enum.reduce(1..count, <<>>, fn index, acc ->
      acc <> <<get_light(leds, index)>>
    end)
  end

  @spec to_list(t) :: list[integer]
  def to_list(%__MODULE__{count: count, leds: _leds, opts: _opts, meta: _meta} = leds) do
    Enum.reduce(1..count, [], fn index, acc ->
      acc ++ [get_light(leds, index)]
    end)
  end

  @spec send(t, map) :: :ok | {:error, String}
  def send(leds, opts \\ %{}) do
    offset = opts[:offset] || 0
    rotate_left = if opts[:rotate_left] != nil, do: opts[:rotate_left], else: true
    server_name = leds.opts.server_name || LedsDriver
    namespace = leds.opts.namespace || :default
    # we probably want to do some validation here and probably
    # want to optimise it a bit
    # a) is the server running?
    if Process.whereis(server_name) == nil do
      Logger.warning("The server #{server_name} wasn't started. You should start it before using this function")
      {:ok, _pid} = LedsDriver.start_link(server_name, %{})
    end
    # b) Is a namespace defined?
    exists = LedsDriver.exist_namespace(server_name, namespace)
    if not exists do
      # Logger.error(Exception.format_stacktrace())
      Logger.warning("The namespace hasn't been defined. This should be done before calling this function")
      :ok = LedsDriver.define_namespace(server_name, namespace)
    end
    vals = rotate(to_list(leds), offset, rotate_left)
    LedsDriver.set_leds(server_name, namespace, vals)
  end

  @spec get_light(t, pos_integer) :: Types.colorint
  def get_light(%__MODULE__{leds: leds} = _leds, index) do
    case Map.fetch(leds, index) do
      {:ok, value} -> value
      _na -> 0
    end
  end

  @spec rotate(list(Types.colorint), pos_integer, boolean) :: list(Types.colorint)
  def rotate(vals, offset, rotate_left \\ true)
  def rotate(vals, 0, _rotate_left), do: vals
  def rotate(vals, offset, rotate_left) do
    count = Enum.count(vals)
    offset = rem(offset, count)
    offset = if rotate_left, do: offset, else: count-offset
    Enum.slide(vals, 0..rem(offset-1 + count, count), count)
  end
end
