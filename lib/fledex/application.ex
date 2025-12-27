# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Application do
  @moduledoc false
  use Application

  @doc """
  The name of the application Supervisor to which we can add
  dynamically supervisors. The AnimationSystem can be added to it
  """
  @app_supervisor Fledex.DynamicSupervisor
  @spec app_supervisor() :: module
  def app_supervisor, do: @app_supervisor

  @impl Application
  @doc false
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: app_supervisor(), strategy: :one_for_one}
      # {Phoenix.PubSub, [name: :fledex, adapter_name: :pg2]},
    ]

    {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)
    {:ok, self()}
  end
end
