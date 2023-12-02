defmodule Fledex.Animation.BaseAnimation do

  alias Fledex.Leds

  @callback start_link(config :: any, strip_name :: atom, animation_name :: atom) :: GenServer.on_start()
  @callback config(strip_name :: atom, animation_name :: atom, config :: map) :: :ok
  @callback get_info(strip_name :: atom, animation_name :: atom) :: any
  @callback shutdown(strip_name :: atom, animation_name :: atom) :: :ok

  @optional_callbacks get_info: 2

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer, opts

      alias Fledex.Animation.BaseAnimation
      # client side
      @spec start_link(config :: config_t, strip_name::atom, animation_name::atom) :: GenServer.on_start()
      def start_link(config, strip_name, animation_name) do
        {:ok, _pid} = GenServer.start_link(__MODULE__, {config, strip_name, animation_name},
                        name: BaseAnimation.build_animator_name(strip_name, animation_name))
      end

      @spec config(atom, atom, config_t) :: :ok
      def config(strip_name, animation_name, config) do
        GenServer.cast(BaseAnimation.build_animator_name(strip_name, animation_name), {:config, config})
      end

      @spec get_info(strip_name :: atom, animation_name :: atom) :: {:ok, any}
      def get_info(strip_name, animation_name) do
        GenServer.call(BaseAnimation.build_animator_name(strip_name, animation_name), :info)
      end

      @spec shutdown(atom, atom) :: :ok
      def shutdown(strip_name, animation_name) do
        GenServer.stop(BaseAnimation.build_animator_name(strip_name, animation_name), :normal)
      end

      defoverridable start_link: 3, config: 3, get_info: 2, shutdown: 2

      # server side
      @impl GenServer
      @spec handle_call(:info, {pid, any}, state_t) :: {:reply, {:ok, map}, state_t}
      def handle_call(:info, _from, state) do
        {:reply, {:ok, state}, state}
      end

      defoverridable handle_call: 3
    end
  end

  @doc """
  This function will create an atomic name for the combination of strip name and
  animation name. This is used to name the animator. It is important that we do
  have a naming convention, because we would otherwise have a hard time to shutdown
  animators that have been removed. We do not keep a reference, but only a config
  Therefore the animator needs to adhere to this naming convention to properly be shut down.
  It is the responsibility of the Animator to set the servername correctly.
  """
  @spec build_animator_name(atom, atom) :: atom
  def build_animator_name(strip_name, animation_name)
    when is_atom(strip_name) and is_atom(animation_name) do
    String.to_atom("#{strip_name}_#{animation_name}")
  end

  @doc false
  @default_leds Leds.leds()
  @spec default_def_func(map) :: Leds.t()
  def default_def_func(_triggers) do
    @default_leds
  end

  @doc false
  @spec default_send_config_func(map) :: %{}
  def default_send_config_func(_triggers) do
    %{}
  end

end
