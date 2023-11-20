defmodule Fledex.Application do
  use Application

  def start(_type, _args) do
    # children = [
    #   %{
    #     id: Phoenix.PubSub.PG2,
    #     start: {Phoenix.PubSub.PG2, :start_link, [:fledex, [
    #       pool_size: 1,
    #       node_name: :fledex
    #     ]]}
    #   },
    # ]
    children = [
      {Phoenix.PubSub, [name: :fledex, adapter_name: :pg2]}
    ]
    {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)
    # Fledex.Animation.LedAnimationManager.run
    {:ok, self()}
  end
end
