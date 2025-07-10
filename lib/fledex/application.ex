# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Application do
  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: Fledex.DynamicSupervisor, strategy: :one_for_one}
      # {Phoenix.PubSub, [name: :fledex, adapter_name: :pg2]},
    ]

    {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)
    {:ok, self()}
  end
end
