defmodule Fledex.Leds do
  require Logger

  use Fledex.Color.Types

  import Bitwise

  alias Fledex.Color.Names
  alias Fledex.Color.Utils
  alias Fledex.Functions
  alias Fledex.LedsDriver

  @enforce_keys [:count, :leds, :opts]
  defstruct count: 0, leds: %{}, opts: %{}, meta: %{index: 1} #, fill: :none
  @type t :: %__MODULE__{count: integer, leds: map, opts: map, meta: map}

  @func_ids %{
    rainbow: &Fledex.Leds.rainbow/2,
    gradient: &Fledex.Leds.gradient/2
  }

  @spec new() :: t
  def new do
    new(0)
  end
  @spec new(integer) :: t
  def new(count) do
    new(count, %{})
  end
  @spec new(integer, map) :: t
  def new(count, opts) do
    new(count, %{}, opts)
  end
  @spec new(integer, map, map) :: t
  def new(count, leds, opts) do
    new(count, leds, opts, %{index: 1})
  end
  @spec new(integer, map, map, map) :: t
  def new(count, leds, opts, meta) do
    %__MODULE__{count: count, leds: leds, opts: opts, meta: meta}
  end

  @spec rainbow(t, map) :: t
  def rainbow(leds, config) do
    num_leds = config[:num_leds] || leds.count
    initial_hue = config[:initial_hue] || 0
    reversed = if config[:reversed], do: config[:reversed], else: false
    offset = config[:offset] || 0

    led_values = Functions.create_rainbow_circular_rgb(num_leds, initial_hue, reversed)
      |> convert_to_leds_structure(offset)

    put_in(leds.leds, Map.merge(leds.leds, led_values))
  end

  @spec convert_to_leds_structure(list(rgb), integer) :: map
  def convert_to_leds_structure(rgbs, offset \\ 0) do
    offset_oneindex = offset + 1
    Enum.zip_with(offset_oneindex..(offset_oneindex + length(rgbs)), rgbs, fn(index, {r, g, b}) ->
      {index, (r <<< 16) + (g <<< 8) + b}
    end) |>  Map.new
  end

  @spec gradient(t, map) :: t
  def gradient(leds, %{start_color: start_color, end_color: end_color} = config) do
    num_leds = config[:num_leds] || leds.count
    offset = config[:offset] || 0

    start_color = Utils.convert_to_subpixels(start_color)
    end_color = Utils.convert_to_subpixels(end_color)

    led_values = Functions.create_gradient_rgb(num_leds, start_color, end_color)
      |> convert_to_leds_structure(offset)

    put_in(leds.leds, Map.merge(leds.leds, led_values))
  end
  def gradient(_leds, _config) do
    raise "You need to specify at least a start_color and end_color"
  end

  @spec light(t, (colorint | t | atom)) :: t
  def light(leds, rgb) do
    do_update(leds, rgb)
  end
  @spec light(t, (colorint | t | atom), pos_integer) :: t
  def light(leds, led, offset) do
    do_update(leds, led, offset)
  end

  @spec func(t, atom, map) :: t
  def func(leds, func_id, config \\ %{}) do
    func = @func_ids[func_id]
    func.(leds, config)
  end

  @spec update(t, (colorint | rgb | atom)) :: t
  def update(leds, led) do
    do_update(leds, led)
  end
  @doc """
  :offset is 1 indexed. Offset needs to be >0 if it's bigger than the :count
  then the led will be stored, but ignored
  """
  @spec update(t, (colorint | t), pos_integer) :: t
  def update(leds, led, offset) when offset > 0 do
    do_update(leds, led, offset)
  end
  def update(_leds, _led, offset) do
    raise ArgumentError, message: "the offset needs to be > 0 (found: #{offset})"
  end

  @spec do_update(t, (colorint | rgb | atom)) :: t
  defp do_update(%__MODULE__{meta: meta} = leds, rgb) do
    index = meta[:index]  || 1
    do_update(leds, rgb, index)
  end
  @spec do_update(t, colorint, pos_integer) :: t
  defp do_update(%__MODULE__{count: count, leds: leds, opts: opts, meta: meta}, rgb, offset) when is_integer(rgb) do
    __MODULE__.new(count, Map.put(leds, offset, rgb), opts, %{meta | index: offset + 1})
  end
  @spec do_update(t, t, pos_integer) :: t
  defp do_update(%__MODULE__{count: count1, leds: leds1, opts: opts1, meta: meta1}, %__MODULE__{count: count2, leds: leds2}, offset) do
    # remap the indicies (1 indexed)
    remapped_new_leds = Map.new(Enum.map(leds2, fn {key, value} ->
      index = offset + key - 1
      {index, value}
    end))
    leds = Map.merge(leds1, remapped_new_leds)
    __MODULE__.new(count1, leds, opts1, %{meta1 | index: offset + count2})
  end
  @spec do_update(t, atom, pos_integer) :: t
  defp do_update(leds, atom, offset) when is_atom(atom) do
    color_int = Names.get_color_int(atom)
    do_update(leds, color_int, offset)
  end
  defp do_update(leds, led, offset) do
    raise ArgumentError, message: "unknown data #{inspect leds}, #{inspect led}, #{inspect offset}"
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

  @spec send(t, map) :: any
  def send(leds, opts \\ %{}) do
    namespace = opts[:namespace] || :default
    server_name = opts[:server_name] || Fledex.LedsDriver
    offset = opts[:offset] || 0
    rotate_left = if opts[:rotate_left] != nil, do: opts[:rotate_left], else: true

    # we probably want to do some validation here and probably
    # want to optimise it a bit
    # a) is the server running?
    if Process.whereis(server_name) == nil do
      Logger.warn("The server wasn't started. You should start it before using this function")
      {:ok, _pid} = LedsDriver.start_link(%{}, server_name)
    end
    # b) Is a namespace defined?
    exists = LedsDriver.exist_namespace(namespace, server_name)
    if not exists do
      Logger.warn("The namespace hasn't been defined. This should be done before calling this function")
      LedsDriver.define_namespace(namespace, server_name)
    end
    vals = rotate(to_list(leds), offset, rotate_left)
    LedsDriver.set_leds(namespace, vals, server_name)
  end

  @spec get_light(t, pos_integer) :: colorint
  def get_light(%__MODULE__{leds: leds} = _leds, index) do
    case Map.fetch(leds, index) do
      {:ok, value} -> value
      _na -> 0
    end
  end

  @spec rotate(list(colorint), pos_integer, boolean) :: list(colorint)
  def rotate(vals, offset, rotate_left \\ true)
  def rotate(vals, 0, _rotate_left), do: vals
  def rotate(vals, offset, rotate_left) do
    count = Enum.count(vals)
    offset = rem(offset, count)
    offset = if rotate_left, do: offset, else: count-offset
    Enum.slide(vals, 0..rem(offset-1 + count, count), count)
  end
end
