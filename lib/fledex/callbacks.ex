defmodule Fledex.Callbacks do
    @callback register(
        list({
            strip_name      :: String | atom,
            strip_options   :: list(keyword),
            loop_name       :: String | atom,
            loop_options    :: list(keyword),
            func            :: (map -> any)
        })
    ) :: :ok | {:error, String} | nil
    @callback register(
        strip_name      :: String | atom,
        strip_options   :: list(keyword),
        loop_name       :: String | atom,
        loop_options    :: list(keyword),
        func            :: (map -> any)
    ) :: :ok | {:error, String} | nil
    @optional_callbacks register: 1, register: 5
end
