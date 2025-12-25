# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.ManagerTestUtils do
  alias Fledex.Supervisor.Utils

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

  def get_job_config(strip_name, job_name) do
    pid = whereis(strip_name, :job, job_name)
    :sys.get_state(pid)
  end
end
