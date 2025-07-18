# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.ManagerTestUtils do
  alias Fledex.Animation.Manager
  alias Fledex.Supervisor.Utils

  def get_manager_config, do: get_manager_config(:animations, :all)
  def get_manager_config(strip), do: get_manager_config(:animations, strip)

  def get_manager_config(what, strip) do
    pid = GenServer.whereis(Manager)
    config = :sys.get_state(pid)

    case what do
      :all ->
        config

      type ->
        config = config[type]

        case strip do
          :all -> config
          name -> config[name]
        end
    end
  end

  def get_animator_config(strip_name, animation_name) do
    pid = GenServer.whereis(Utils.via_tuple(strip_name, :animator, animation_name))
    :sys.get_state(pid)
  end

  @spec whereis(atom, :animator | :job | :coordinator | :led_strip, atom) :: GenServer.name()
  def whereis(strip_name, type, other_name),
    do: GenServer.whereis(Utils.via_tuple(strip_name, type, other_name))

  def stop_if_running(name, reason \\ :normal) do
    pid = Process.whereis(name)

    if pid != nil do
      GenServer.stop(pid, reason)
    end
  end
end
