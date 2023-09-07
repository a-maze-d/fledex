defmodule Fledex.Callbacks do
    @callback register(
        strip_name      :: String | atom, 
        strip_options   :: list(keyword),
        loop_name       :: String | atom,
        loop_options    :: list(keyword), 
        func            :: (map -> any) ) :: :ok | {:error, String} | nil
end