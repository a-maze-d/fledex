# NOTE: This module is very much in a brain-storming phase and surely will not work
# yet. The best is if you ignore it for now :-)
defmodule Fledex do
  @moduledoc """
  This module should provide some simple macros that allow to define the
  led strip and to update it. The code you would write (in livebook) would
  look something like the following:
  iex> led_chain do
      live_loop :john, do
        with_opts :send_config, %{offset: counter}
        with_opts :delay_config, counter

        config = %{
          num_leds: 50,
          reversed: true
        }

        Leds.new(50)
        |> Leds.func(:rainbow, config)
      end
    end
  """
  # defmacro __using__(_opts) do
  #   quote do
  #     import Fledex
  #     Module.register_attribute(__MODULE__, :loop, accumulate: true)
  #     Module.register_attribute(__MODULE__, :with_opts, accumulate: true)
  #     # @before_compile Fledex
  #   end
  # end

  # defmacro __before_compile__(_env) do

  # end

  require Fledex
  alias Fledex.LedsDriver
  # @doc """
  #   This is for the case the led_strip got forgotten. We inject a default one
  # """
  # defmacro live_loop(name, do: expression) do
  #   quote do
  #     led_strip do
  #       live_loop unquote(name) do
  #         unquote(expression)
  #       end
  #     end
  #   end
  # end
  # def build_func(expression) do
  #   quote do
  #     fn(data) ->
  #       unquote(
  #         expression
  #       )
  #     end
  #   end
  #   expression
  # end
@doc """
  we get an expression in and we convert it to a function
  ```elixir
    iex(1)> quote(do: fn(data) -> data+1 end)
      {:fn, [],
      [
        {:->, [],
          [
            [{:data, [], Elixir}],
            {:+, [context: Elixir, imports: [{1, Kernel}, {2, Kernel}]],
            [{:data, [], Elixir}, 1]}
          ]}
      ]}
    iex(2)> quote(do: fn(data) -> true end)
      {:fn, [], [{:->, [], [[{:data, [], Elixir}], true]}]}
    ```
    iex(3)> quote(do: fn(Macro.var!(data)) -> true end)
      {:fn, [],
      [
        {:->, [],
          [
            [
              {{:., [], [{:__aliases__, [alias: false], [:Macro]}, :var!]}, [],
              [{:data, [], Elixir}]}
            ],
            true
          ]}
      ]}

  """
  def build_function(expression) do
    IO.puts(inspect expression)
    func = {:fn, [], [{:->, [], [[{:data, [], Elixir}], expression]}]}
    IO.puts(inspect func)
    IO.puts(Macro.to_string(func))
    func
  end
  # def build_function(expression) do
  #   # {:fn, [],
  #   #  [
  #   #    {:->, [],
  #   #     [
  #   #       [
  #   #         {{:., [], [{:__aliases__, [alias: false], [:Macro]}, :var!]}, [],
  #   #          [{:data, [], Elixir}]}
  #   #       ],
  #   #      expression
  #   #     ]}
  #   #  ]}
  #       IO.puts(inspect expression)
  #       func = {:fn, [], [{:->, [], [[{:data, [], Elixir}], Macro.escape(expression)]}]}
  #       IO.puts(inspect func)
  #       IO.puts(Macro.to_string(func))
  #       func
  #  end
# @doc ~S"""
  #   This introduces a new led_strip. Probably we only have a single
  #   led strip and then the default name (the module name) will be used.
  # """
  # defmacro led_strip(server_name \\ LedsDriver, do: expression) do
  #   # collect_live_loops()
  #   #   |> sync_live_loop_definitions_with_server(server_name)
  #   quote do
  #     @server_name unquote(server_name)
      @doc """
      This introduces a new `ive_loop` (animation) that will be played over
      and over again until it is changed. Therefore we we give it a name to
      know whether it changes
      """
      defmacro live_loop(name, with_opts \\ [], do: ast) do
        # @loop [{unquote(server_name), unquote(name)} | @loop]
        # quote do
        #   defmacro with_opts(type, value) do
        #     quote do
        #       @with_opts [{unqote(name), unquote(type), unquote(value)} | @with_opts]
        #     end
        #   end
        #   with_opts = Enum.filter(@with_opts, fn(item) ->
        #     case item do
        #       {^server_name, ^name, _type, _value} -> true
        #       _ -> false
        #     end
        #   end)
        #   |> Enum.map(fn({_server_name, _name, type, value} = item) ->
        #     {type, value}
        #   end)
        # quote do
        #   func = fn(data) ->
        #     Macro.to_string()
        #     data = Macro.generate_arguments(1,__MODULE__)
        #     unquote(expression)
        #   end
        func = quote do
          build_function(Macro.escape(unquote(ast)))
        end
        quote do
          register(unquote(name), unquote(with_opts), unquote(Macro.escape(func)))
        end
        # quote do
        #   register(unquote(name), unquote(with_opts), unquote(func))
        # end
      end
    # end
  # end

  def register(name, with_opts, expression) do
    IO.puts(" name: #{inspect name}, options: #{inspect with_opts}, expression: #{inspect expression}")
    check_env(LedsDriver, name)
    data = %{something: 10}
    result = expression.(data)
    IO.puts("evaluting expression: #{result}")
  end
  defp check_env(_server_name, _name) do
    # is the server running (with the specified name)?
    # do we have a Leds defined (with the specified name)?
  end
end

defmodule F.Test do
  def run() do
    import Fledex
    # led_strip do
      live_loop :john, test: 10, tset: "string1" do
        true
        # _e = data.something
        # with_opts test:  10
        # with_opts tset: "string1"
        # IO.puts "server_name: #{inspect @server_name}"
      end
    # end
  end
end
