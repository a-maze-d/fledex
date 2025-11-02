# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Utils.PubSub do
  @moduledoc """
  This module collects all functions that are about publish and subscribe (PubSub)
  functionality.

  PubSub is used for 2 things (more things are likely to be added in the future):
  * Notifications related to `trigger`s (when repaints happen). You can inject into this information flow by calling `broadcast_trigger/1`
  * Notifications related to `state` changes. Those are triggered mainly by effects, but also an animation can publish them. `Fledex.Animation.Coordinator`s are the main consumer of those events to then take appopriate actions. Those events are published through `broadcast_state/2`
  """
  alias Fledex.Supervisor.Utils

  @channel_trigger "trigger"
  @channel_state "state"

  require Phoenix.PubSub
  @doc delegate_to: {Phoenix.PubSub, :subscribe, 2}
  defdelegate subscribe(pubsub \\ Utils.pubsub_name(), topic), to: Phoenix.PubSub
  defdelegate unsubscribe(pubsub \\ Utils.pubsub_name(), topic), to: Phoenix.PubSub
  defdelegate broadcast(pubsub \\ Utils.pubsub_name(), topic, message), to: Phoenix.PubSub

  defdelegate direct_broadcast!(node, pubsub \\ Utils.pubsub_name(), topic, message),
    to: Phoenix.PubSub

  # @spec app() :: atom
  # def app, do: @app
  @spec channel_trigger() :: String.t()
  def channel_trigger, do: @channel_trigger
  @spec channel_state() :: String.t()
  def channel_state, do: @channel_state

  @spec broadcast_trigger(map) :: :ok | {:error, term()}
  def broadcast_trigger(message) when is_map(message) do
    broadcast(Utils.pubsub_name(), @channel_trigger, {:trigger, message})
  end

  @spec broadcast_state(any, map) :: :ok | {:error, term()}
  def broadcast_state(state, context) when is_map(context) do
    broadcast(Utils.pubsub_name(), @channel_state, {:state_change, state, context})
  end
end
