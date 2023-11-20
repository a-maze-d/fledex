defmodule Fledex.Animation.BaseAnimation do

  alias Fledex.Leds

  @callback start_link(config :: any, strip_name :: atom, animation_name :: atom) :: GenServer.on_start()
  @callback config(strip_name :: atom, animation_name :: atom, config :: map) :: :ok
  @callback get_info(strip_name :: atom, animation_name :: atom) :: any
  @callback shutdown(strip_name :: atom, animation_name :: atom) :: :ok

  @optional_callbacks [get_info: 2]

  @doc """
    This function will create an atomic name for the combination of strip name and
    animation name. This is used to name the animator. It is important that we do
    have a naming convention, because we would otherwise have a hard time to shutdown
    animators that have been removed. We do not keep a reference, but only a config
    Therefore the animator needs to adhere to this naming convention to properly be shut down.
    It is the responsibility of the Animator to set the servername correctly.
  """
  @spec build_strip_animation_name(atom, atom) :: atom
  def build_strip_animation_name(strip_name, animation_name)
    # TODO: I don't like this name
    when is_atom(strip_name) and is_atom(animation_name) do
    String.to_atom("#{strip_name}_#{animation_name}")
  end

  # TODO: why do we define 30 leds and not 0?
  @default_leds Leds.leds(30)
  def default_def_func(_triggers) do
    @default_leds
  end
  def default_send_config_func(_triggers) do
    %{}
  end

end
