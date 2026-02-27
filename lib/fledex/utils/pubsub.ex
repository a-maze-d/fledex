# Copyright 2023-2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Utils.PubSub do
  @moduledoc """
  This module collects all functions that are about publish and subscribe (PubSub)
  functionality.

  PubSub is used for 2 things.
  * Notifications related to `trigger`s (when repaints happen). You can inject into this information flow by calling `publish_trigger/1`
  * Notifications related to `state` changes. Those are triggered mainly by effects, but also an animation can publish them. `Fledex.Animation.Coordinator`s are the main consumer of those events to then take appopriate actions. Those events are published through `publish_effect_event/2`

  You can consider the first one as a channel towards the animation and the latter as a channel from the animation/effect/...
  """
  alias Fledex.Supervisor.Utils

  @channel_trigger "trigger"
  @channel_state "state"

  @typedoc """
  The effect state can can send any of those events mostly triggered by effects and animations. The coordinator can then react to those events and thereby influence the effects and animations (example, enable/disable them, change some options, ...)

  If you want to send a custom event, you can use the `effect_info_event_t/0` (usually in combination with the `:change` event) to send custom information:

  * `:start`: effect will start with the next iteration (and will move into the :progress state).
  * `:middle`: offen an effect consists of 2 phases (back and forth, wanish and reappear, ...). This event indicates the mid-point.
  * `:end`:  effect has reached it's final state. If the effect cycles in rounds, the next step will restart the effect. If you plan to restart, the effect, you should be careful that the `:end` and `:start` result in a smooth transition (and no jump too early or too late)
  * `:change`: some change happened. This event is most commonly used with extra info to specify the details of the change (like moved the offset by 10 pixels). See `effect_info_event_t/0` for more info
  * `:disabled`: the effect or animation has been disabled

  > #### Note {: .info}
  >
  > This is not used yet and still very much in flux
  """
  @type effect_event_t :: :start | :middle | :end | :disabled | :change

  @typedoc """
  This is an extention of the `effect_event_t` that can carry additional information. This is especially important for the `:change` even, but it can be used with the other even types too.

  > #### Note: {: .info}
  > Don't duplicate the information that is already present in the options
  """
  @type effect_info_event_t :: effect_event_t() | {effect_event_t(), any}

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
  @spec publish_trigger(map) :: :ok | {:error, term()}
  def publish_trigger(message) when is_map(message) do
    broadcast(Utils.pubsub_name(), @channel_trigger, {:trigger, message})
  end

  @doc """
  Use this function if you want to publish to the `channel_state/0` channel
  """
  @spec publish_effect_event(effect_info_event_t(), map) :: :ok | {:error, term()}
  def publish_effect_event(effect_event, context) when is_map(context) do
    broadcast(Utils.pubsub_name(), @channel_state, {:state_change, effect_event, context})
  end
end
