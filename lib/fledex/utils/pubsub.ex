defmodule Fledex.Utils.PubSub do
  require Phoenix.PubSub
  defdelegate subscribe(pubsub, topic), to: Phoenix.PubSub
  defdelegate unsubscribe(pubsub, topic), to: Phoenix.PubSub
  defdelegate broadcast(pubsub, topic, message), to: Phoenix.PubSub
end
