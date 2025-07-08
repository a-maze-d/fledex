# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Supervisor.WorkerSupervisor do
  use DynamicSupervisor
  alias Fledex.Animation.Animator
  alias Fledex.Animation.Coordinator
  alias Fledex.Driver.Impl.Null
  alias Fledex.LedStrip
  alias Fledex.Supervisor.Utils

  def start_link(_arg),
    do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_arg),
    do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_animation(strip_name, animation_name, config) do
    # IO.puts("Supervisor asked to start animation... #{inspect {strip_name, animation_name}}")
    DynamicSupervisor.start_child(
      Utils.worker_supervisor(),
      %{
        id: animation_name,
        start: {Animator, :start_link, [config, strip_name, animation_name]},
        restart: :transient
      }
    )
  end

  @spec start_led_strip(atom, module | {module, keyword} | [{module, keyword}], keyword) ::
          LedStrip.start_link_response()
  def start_led_strip(strip_name, drivers \\ Null, strip_config \\ []) do
    DynamicSupervisor.start_child(
      Utils.worker_supervisor(),
      %{
        id: strip_name,
        start: {LedStrip, :start_link, [strip_name, drivers, strip_config]},
        restart: :transient
      }
    )
  end
  def start_coordinator(strip_name, coordinator_name, config) do
    # IO.puts("starting corrdinator (1)... #{inspect {strip_name, coordinator_name, config}}")
    DynamicSupervisor.start_child(
      Utils.worker_supervisor(),
      %{
        id: strip_name,
        start: {Coordinator, :start_link, [strip_name, coordinator_name, config]},
        restart: :transient
      }
    )
  end
end
