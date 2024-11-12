# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Leds do
  @moduledoc """
  This module allows to define a sequence of Leds. You first create the new sequence of leds
  by calling one of the `leds` functions.

  **Note:** usually the `leds` function would rather be called `new` but when importing the `Leds`
  module, it becomes more natural to say

  ```elixir
    leds(10) |> light(:red)`
  ```

  To keep the classical semantics some delegates are defined, so you can use `new` as well.
  """
  require Logger

  alias Fledex.Color.Functions
  alias Fledex.Color.Types
  alias Fledex.Color.Utils
  alias Fledex.Effect.Rotation
  alias Fledex.LedStrip

  @enforce_keys [:count, :leds, :opts]
  defstruct count: 0, leds: %{}, opts: %{}, meta: %{index: 1}

  @type t :: %__MODULE__{
          count: integer,
          leds: %{pos_integer => Types.colorint()},
          opts: %{atom => any},
          meta: %{atom => any}
        }

  @doc delegate_to: {Leds, :leds, 0}
  defdelegate new(), to: Fledex.Leds, as: :leds
  @doc delegate_to: {Leds, :leds, 1}
  defdelegate new(count), to: Fledex.Leds, as: :leds
  @doc delegate_to: {Leds, :leds, 2}
  defdelegate new(count, opts), to: Fledex.Leds, as: :leds
  @doc delegate_to: {Leds, :leds, 3}
  defdelegate new(count, leds, opts), to: Fledex.Leds, as: :leds
  @doc delegate_to: {Leds, :leds, 4}
  defdelegate new(count, leds, opts, meta), to: Fledex.Leds, as: :leds

  @doc """
  Create a new led sequence of length 0.

  This is rarely useful. Use the `leds/1` function instead (or change the count by using `set_count/2`)
  """
  @spec leds() :: t
  def leds do
    leds(0)
  end

  @doc """
  Creates a new led sequence with a set number of leds
  """
  @spec leds(integer) :: t
  def leds(count) do
    leds(count, %{})
  end

  @doc """
  Create a new led sequence with a set number of leds and some options.

  Currently two options are available:

  * `:server_name` and
  * `:namespace`.

  Those are important when you want to send your led sequence to an
  `Fledex.LedStrip`.
  You should prefer to use the `set_led_strip_info/3` function instead.
  """
  @spec leds(integer, map) :: t
  def leds(count, opts) do
    leds(count, %{}, opts)
  end

  @doc """
  Create a new led sequence with a set number of leds, some set leds and options.

  This function is similar to `leds/2`, but you  an specify some leds (between the `count`
  and the `opts`) through a map or a list.

  If a map is used the key of the map (an integer) is the index (one-indexed) of the
  led and the value is the color.
  If a list is used each entry in the list defines a color. Internally it will be converted
  to a map.

  Leds that are outside the `count` can be specified, but will be ignored when sent to
  an `Fledex.LedStrip` through the `send/2` function.
  """
  @spec leds(integer, list(Types.color()) | %{integer => Types.color()}, map) :: t
  def leds(count, leds, opts) do
    leds(count, leds, opts, %{})
  end

  @doc """
  Creates a led sequence with a set number of leds, some set leds, some options and some
  meta information.

  This function is similar to the `leds/3` function, but some additional meta information
  can be specified. Currently the only  meta information is to keep track of an index
  that specfies which led will be set when using the `light/2` function, i.e. without
  an offset. This way it's possible to have a sequence of updates like the following
  to specify the colors:

  ```elixir
  leds(10) |> light(:red) |> light(:blue)
  ```
  """
  @spec leds(integer, list(Types.color()) | %{integer => Types.color()}, map, map) :: t
  def leds(count, leds, opts, meta) when is_list(leds) do
    leds(count, convert_to_leds_structure(leds, 0), opts, meta)
  end

  def leds(count, leds, opts, meta) when is_map(leds) do
    default_opts = %{namespace: nil, server_name: nil}
    default_meta = %{index: 1}

    %__MODULE__{
      count: count,
      leds: leds,
      opts: Map.merge(default_opts, opts || %{}),
      meta: Map.merge(default_meta, meta || %{})
    }
  end

  @doc """
  This function sets the count of leds of the led sequence.

  Note: Be careful if you redefine the count when some leds have
  been defined outside of the previous range; they might suddenly become
  visible.
  """
  @spec set_count(t, pos_integer) :: t
  def set_count(%__MODULE__{} = leds, count) do
    put_in(leds.count, count)
  end

  @doc """
  This function checks how many leds are defined in the led sequence.

  Note: The color of an led outside that range can be defined, but it won't be
  send to the `Fledex.LedStrip` when the `send/2` function is called. See also
  `set_count/2` for information.
  """
  @spec count(t) :: pos_integer
  def count(%__MODULE__{count: count} = _leds) do
    count
  end

  @doc """
  Define the server_name and the namespace

  This is used when the led sequence is sent to the `Fledex.LedStrip` when the
  `send/2` function is called.
  """
  @spec set_led_strip_info(t, namespace :: atom, server_name :: atom) :: t
  def set_led_strip_info(%{opts: opts} = leds, namespace, server_name \\ Fledex.LedStrip) do
    opts = %{opts | server_name: server_name, namespace: namespace}
    %__MODULE__{leds | opts: opts}
  end

  @doc """
  Defines a rainbow over the leds. The options that can be specified are:

  *  `:num_leds`: how many leds should be part of the rainbow (by default all leds)
  * `:offset`: as from which led we want to start the  rainbow (default: 0, no offset)
  * `:reversed`: The rainbow can go from red (start color) to blue (end color) or the other
      way around.
  * `:initial_hue`: The starting color in degree (`0..360`). (default: 0)

  Note: any led that has been defined before calling this function will be overwritten
  with the rainbow value.
  """
  @spec rainbow(t, map) :: t
  def rainbow(%__MODULE__{} = leds, opts \\ %{}) do
    num_leds = Map.get(opts, :num_leds, leds.count)
    reversed = Map.get(opts, :reversed, false)
    offset = Map.get(opts, :offset, 0)
    initial_hue = Map.get(opts, :initial_hue, 0)

    led_values =
      Functions.create_rainbow_circular_rgb(num_leds, initial_hue, reversed)
      |> convert_to_leds_structure(offset)

    put_in(leds.leds, Map.merge(leds.leds, led_values))
  end

  @doc """
  Helper function to convert a list of colors to the correct map structure
  """
  @spec convert_to_leds_structure(list(Types.color()), integer) :: map
  def convert_to_leds_structure(rgbs, offset \\ 0) do
    offset_oneindex = offset + 1

    Enum.zip_with(offset_oneindex..(offset_oneindex + length(rgbs)), rgbs, fn index, rgb ->
      {index, Utils.to_colorint(rgb)}
    end)
    |> Map.new()
  end

  @doc """
  Defines the leds through a gradient function.

  The gradient function will create a smoot transition from a `start_color` to an
  `end_color`. The options that can be specified are the following:

  * `"num_leds`: Over how many leds the transition should happen. (default: all)
  * `:offset`: The offset where to start the gardient at (default: 0)
  """
  @spec gradient(t, Types.color(), Types.color(), keyword) :: t
  def gradient(%__MODULE__{} = leds, start_color, end_color, opts \\ []) do
    num_leds = opts[:num_leds] || leds.count
    offset = opts[:offset] || 0

    start_color = Utils.to_rgb(start_color)
    end_color = Utils.to_rgb(end_color)

    led_values =
      Functions.create_gradient_rgb(num_leds, start_color, end_color)
      |> convert_to_leds_structure(offset)

    put_in(leds.leds, Map.merge(leds.leds, led_values))
  end

  @doc """
  repeat teh existing sequence `amount` times

  This way you can easily create a repetitive pattern

  **Note:** this will change the led sequence count  (`amount` times the initial `count`)
  """
  @spec repeat(t, integer) :: t
  def repeat(
        %__MODULE__{
          count: count,
          leds: leds,
          opts: opts,
          meta: meta
        },
        amount
      )
      when amount >= 1 do
    index = meta[:index] || 1
    new_index = (amount - 1) * count + index
    new_count = count * amount

    new_leds =
      Enum.reduce(2..amount, leds, fn round, acc ->
        Map.merge(acc, remap_leds(leds, count * (round - 1) + 1))
      end)

    __MODULE__.leds(new_count, new_leds, opts, %{meta | index: new_index})
  end

  @doc """
  Defines the color(s) of the next led

  If there are no more leds, this function will virtually continue and define leds
  outside the scope, see also the note on `set_count/2`.

  Note: it is possible to use a sub sequence of leds and they all will be added to
  the sequence.
  """
  @spec light(t, Types.color() | t) :: t
  def light(leds, rgb) do
    do_update(leds, rgb)
  end

  @doc """
  Defines the color of an led at `position` (one indexed)

  The `offset` needs to be `> 0` if it's bigger than the count
  then the led will be stored, but ignored (but see the description
  of `set_count/2`). The same note as for `light/2` applies.
  """
  @spec light(t, Types.color() | t, pos_integer) :: t
  def light(leds, led, offset) when offset > 0 do
    do_update(leds, led, offset)
  end

  def light(_leds, _led, offset) do
    raise ArgumentError, message: "the offset needs to be > 0 (found: #{offset})"
  end

  @doc """
  Defines the color of an led at `position` and repeats it `repeat` times.

  THe `repeat` needs to be more than 1, otherwise it wouldn't make sense.
  In adition the same note as for `light/2` applies.
  """
  @spec light(t, Types.color() | t, pos_integer, pos_integer) :: t
  def light(%__MODULE__{} = leds, led, offset, repeat) when offset > 0 and repeat >= 1 do
    # convert led to a LEDs struct
    led =
      case led do
        led when is_integer(led) -> __MODULE__.leds(1) |> __MODULE__.light(led)
        led when is_atom(led) -> __MODULE__.leds(1) |> __MODULE__.light(led)
        %__MODULE__{} = led -> led
      end

    # repeat the sequence
    led = led |> __MODULE__.repeat(repeat)
    # merge in the sequence at the coorect offset
    __MODULE__.light(leds, led, offset)
  end

  def light(_leds, _led, offset, repeat) do
    raise ArgumentError,
      message: "the offset needs to be > 0 (found: #{offset}) and repeat >= 1 (found: #{repeat})"
  end

  @spec do_update(t, Types.color() | t) :: t
  defp do_update(%__MODULE__{meta: meta} = leds, rgb) do
    index = meta[:index] || 1
    index = max(index, 1)
    do_update(leds, rgb, index)
  end

  @spec do_update(t, Types.color() | t, pos_integer) :: t
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

  defp do_update(
         %__MODULE__{count: count, leds: leds, opts: opts, meta: meta},
         color,
         offset
       ) do
    color_int = Utils.to_colorint(color)
    __MODULE__.leds(count, Map.put(leds, offset, color_int), opts, %{meta | index: offset + 1})
  end

  defp do_update(leds, led, offset) do
    raise ArgumentError,
      message: "unknown data #{inspect(leds)}, #{inspect(led)}, #{inspect(offset)}"
  end

  @spec remap_leds(%{pos_integer => Types.colorint()}, pos_integer) :: %{
          pos_integer => Types.colorint()
        }
  defp remap_leds(leds, offset) do
    Map.new(
      Enum.map(leds, fn {key, value} ->
        index = offset + key - 1
        {index, value}
      end)
    )
  end

  @doc """
  Convert the sequence of leds to a binary sequence of `Fledex.Color.Types.colorint` colors.

  Note: Only the leds that are inside the `count` will be emitted into the binary sequence.
  """
  @spec to_binary(t) :: binary
  def to_binary(%__MODULE__{count: count, leds: _leds, opts: _opts, meta: _meta} = leds) do
    Enum.reduce(1..count, <<>>, fn index, acc ->
      acc <> <<get_light(leds, index)>>
    end)
  end

  @doc """
  Convert the sequence of leds into an list of `Fledex.Color.Types.colorint` colors.

  Note: Only the leds that are inside the `count` will be added to the list.
  """
  @spec to_list(t) :: list(Types.colorint())
  def to_list(%__MODULE__{count: count, leds: _leds, opts: _opts, meta: _meta} = leds)
      when count > 0 do
    Enum.reduce(1..count, [], fn index, acc ->
      acc ++ [get_light(leds, index)]
    end)
  end

  def to_list(_leds) do
    []
  end

  @base16 16
  @block <<"\u2588">>
  @doc """
  Convert the sequence of leds to a markdown representation.

  The #{@block} will be used to represent the leds and they will be colored in
  the appropriate color. It then looks something like this:
  <span style="color: #ff0000">#{@block}</span>
  <span style="color: #00ff00">#{@block}</span>
  <span style="color: #0000ff">#{@block}</span>
  The opts are currently not used, but are planned to
  be used for potential color correction (similar to `Fledex.Driver.Impl.Kino`)
  """
  @spec to_markdown(t, map) :: String.t()
  def to_markdown(leds, _opts \\ %{}) do
    leds
    |> Fledex.Leds.to_list()
    # |> Correction.apply_rgb_correction(config.color_correction)
    |> Enum.reduce(<<>>, fn value, acc ->
      hex =
        value
        |> Integer.to_string(@base16)
        |> String.pad_leading(6, "0")

      acc <> "<span style=\"color: ##{hex}\">" <> @block <> "</span>"
    end)
  end

  @doc """
  Convenience function to send the led sequence to an `Fledex.LedStrip`.

  In order for the function to succeed either `set_led_strip_info/3` needs to be
  called or the information needs to be passed as part of the opts. The opts can
  be the following:

  * `:offset`: Move the led sequence to the side (see Note below)
  * `:rotate_left`: whether the offset should be appiled toward the right or the left
  * `:server_name`: The name of the server_name to which the led sequence should be send to
      (default: `Fledex.LedStrip`)
  * `:namespace`: The name of the namespace within the LedStrip (default: `:default`)

  Note: the led sequence will always be applied in it's entirety, and will wrap around.
  Through the `:offset` it is possible to create simple animations by simply counting up
  up the counter.

  Note2: If no `server_name` and/or no `namespace` are defined, then they will be defined
  (and started). A warning will be emitted to the concole.
  """
  @spec send(t, map) :: :ok | {:error, String.t}
  def send(leds, opts \\ %{}) do
    offset = opts[:offset] || 0
    rotate_left = if opts[:rotate_left] != nil, do: opts[:rotate_left], else: true
    server_name = leds.opts.server_name || LedStrip
    namespace = leds.opts.namespace || :default
    # we probably want to do some validation here and probably
    # want to optimise it a bit
    # a) is the server running?
    _ = if Process.whereis(server_name) == nil do
      Logger.warning(
        "The server #{server_name} wasn't started. You should start it before using this function"
      )

      {:ok, _pid} = LedStrip.start_link(server_name)
    end

    # b) Is a namespace defined?
    exists = LedStrip.exist_namespace(server_name, namespace)

    if not exists do
      # Logger.error(Exception.format_stacktrace())
      Logger.warning(
        "The namespace hasn't been defined. This should be done before calling this function"
      )

      :ok = LedStrip.define_namespace(server_name, namespace)
    end

    offset = if leds.count == 0, do: 0, else: rem(offset, leds.count)
    vals = Rotation.rotate(to_list(leds), leds.count, offset, rotate_left)
    LedStrip.set_leds(server_name, namespace, vals)
  end

  @doc """
  Retrieve the color of an led at a specific position
  """
  @spec get_light(t, pos_integer) :: Types.colorint()
  def get_light(%__MODULE__{leds: leds} = _leds, index) when index > 0 do
    case Map.fetch(leds, index) do
      {:ok, value} -> value
      _na -> 0
    end
  end

  # @doc """
  # Helper function mainy intended for internal use to rotate the sequence of values by an `offset`.

  # The rotation can happen with the offset to the left or to the right.
  # """
  # @spec rotate(list(Types.colorint), pos_integer, boolean) :: list(Types.colorint)
  # def rotate(vals, offset, rotate_left \\ true)
  # def rotate(vals, 0, _rotate_left), do: vals
  # def rotate(vals, offset, rotate_left) do
  #   count = Enum.count(vals)
  #   offset = rem(offset, count)
  #   offset = if rotate_left, do: offset, else: count-offset
  #   Enum.slide(vals, 0..rem(offset-1 + count, count), count)
  # end

  defimpl Kino.Render, for: Fledex.Leds do
    @moduledoc """
    Implementation of the `Kino.Render` protocol for `Fledex.Leds`

    The rendering will happen as an led representation (see `to_markdown/2`)
    as well as a texutal representation. The user can change between the two
    through tabs

    **Note:** Ensure  that the protocols are not consolidated by spacifying:
    `consolidate_protocols: false`
    """
    alias Fledex.Leds

    @doc delegate_to: {Kino.Reader, :to_livebook, 1}
    @impl true
    @spec to_livebook(Fledex.Leds.t()) :: map
    def to_livebook(leds) do
      md_kino = Kino.Markdown.new(Leds.to_markdown(leds))
      i_kino = Kino.Inspect.new(leds)

      kino =
        Kino.Layout.tabs(
          Leds: md_kino,
          Raw: i_kino
        )

      Kino.Render.to_livebook(kino)
    end
  end
end
