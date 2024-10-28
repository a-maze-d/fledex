# Copyright 2023-2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Utils.PubSub do
  @app Mix.Project.config()[:app]
  @channel_trigger "trigger"
  @channel_state "state"

  require Phoenix.PubSub
  defdelegate subscribe(pubsub, topic), to: Phoenix.PubSub
  defdelegate unsubscribe(pubsub, topic), to: Phoenix.PubSub
  defdelegate broadcast(pubsub, topic, message), to: Phoenix.PubSub
  defdelegate direct_broadcast!(node, pubsub, topic, message), to: Phoenix.PubSub

  def app, do: @app
  def channel_trigger, do: @channel_trigger
  def channel_state, do: @channel_state

  def broadcast_trigger(message) when is_map(message) do
    broadcast(@app, @channel_trigger, {:trigger, message})
  end

  def broadcast_state(state, context) when is_atom(state) and is_map(context) do
    broadcast(@app, @channel_state, {:state_change, state, context})
  end
end
