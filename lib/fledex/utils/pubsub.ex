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

  @doc delegate_to: {Phoenix.PubSub, :subscribe, 2}
  defdelegate subscribe(pubsub \\ Utils.pubsub_name(), topic), to: Phoenix.PubSub
  @doc delegate_to: {Phoenix.PubSub, :unsubscribe, 2}
  defdelegate unsubscribe(pubsub \\ Utils.pubsub_name(), topic), to: Phoenix.PubSub
  @doc delegate_to: {Phoenix.PubSub, :broadcast, 3}
  defdelegate broadcast(pubsub \\ Utils.pubsub_name(), topic, message), to: Phoenix.PubSub

  @doc delegate_to: {Phoenix.PubSub, :direct_broadcast, 4}
  defdelegate direct_broadcast!(node, pubsub \\ Utils.pubsub_name(), topic, message),
    to: Phoenix.PubSub

  @doc """
  Name of the channel to which trigger events will be published.
  Trigger events are those that are related to the redrawing of the led strip
  """
  @spec channel_trigger() :: String.t()
  def channel_trigger, do: @channel_trigger

  @doc """
  Name of the channel to which state events will be published.
  State events are those that are related to animations and effects and are important
  for coordinators.
  """
  @spec channel_state() :: String.t()
  def channel_state, do: @channel_state

  @doc """
  Use this function if you want to publish to the trigger channel

  See also the `channel_trigger/0` for more informration.
  """
  @spec broadcast_trigger(map) :: :ok | {:error, term()}
  def broadcast_trigger(message) when is_map(message) do
    broadcast(Utils.pubsub_name(), @channel_trigger, {:trigger, message})
  end

  @doc """
  Use this function if you want to publish to the state channel

  See also the `channel_state/0` for more informration.
  """
  @spec broadcast_state(any, map) :: :ok | {:error, term()}
  def broadcast_state(state, context) when is_map(context) do
    broadcast(Utils.pubsub_name(), @channel_state, {:state_change, state, context})
  end
end
