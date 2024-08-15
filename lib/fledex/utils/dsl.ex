# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Utils.Dsl do
  alias Fledex.Animation.Manager
  alias Fledex.Leds

  @fledex_macros [
    :animation,
    :static,
    :job,
    :coordinator,
    :component,
    :effect
  ]

  # @spec fledex_config :: %{atom => module}
  # def fledex_config do
  #   @fledex_config
  # end

  @spec create_config(atom, atom, (map -> Leds.t()), keyword | nil) :: Manager.configs_t()
  def create_config(name, type, def_func, options)
      when is_atom(name) and is_atom(type) and
             (is_function(def_func, 1) or is_function(def_func, 2)) do
    %{
      name => %{
        type: type,
        def_func: def_func,
        options: options || [],
        effects: []
      }
    }
  end

  @spec create_config(atom, atom, keyword | nil) :: Manager.configs_t()
  def create_config(name, module, opts) do
    module.configure(name, opts)
  end

  @spec apply_effect(atom, keyword, Manager.configs_t() | [Manager.configs_t()]) ::
          Manager.configs_t()
  def apply_effect(module, options, block)
      when is_atom(module) and is_list(options) and is_map(block) do
    apply_effect(module, options, [block])
  end

  def apply_effect(module, options, block)
      when is_atom(module) and is_list(options) and is_list(block) do
    block
    # merge list of configs
    |> Enum.reduce(%{}, fn config, acc ->
      Map.merge(acc, config)
    end)
    # add effect to each config
    |> Enum.map(fn {name, config} ->
      {name, %{config | effects: [{module, options} | config.effects]}}
    end)
    # convert back to a map
    |> Map.new()
  end

  def apply_effect(module, options, block) do
    raise ArgumentError,
          "Unknown block. I don't know how to apply the effect #{module} with options #{inspect(options)} on #{inspect(block)}"
  end

  @spec configure_strip(
          atom,
          :config | module | {module, keyword} | [{module, keyword}],
          keyword,
          [Manager.configs_t()] | Manager.configs_t()
        ) :: :ok | Manager.configs_t()
  def configure_strip(strip_name, drivers, strip_options, config) when is_list(config) do
    config =
      Enum.reduce(config, %{}, fn map, acc ->
        Map.merge(acc, map)
      end)

    configure_strip(strip_name, drivers, strip_options, config)
  end

  def configure_strip(_strip_name, :config, _strip_options, config), do: config

  def configure_strip(strip_name, driver, strip_options, config) when is_atom(driver) do
    configure_strip(strip_name, {driver, []}, strip_options, config)
  end

  def configure_strip(
        strip_name,
        {_driver_module, _driver_config} = driver,
        strip_options,
        config
      ) do
    configure_strip(strip_name, [driver], strip_options, config)
  end

  def configure_strip(strip_name, drivers, strip_options, config) when is_list(drivers) do
    # if is_atom(strip_options) and strip_options == :config do
    #   config
    # else
    Manager.register_strip(strip_name, drivers, strip_options)
    Manager.register_config(strip_name, config)
    # end
  end

  @spec init(keyword) :: :ok | {:ok, pid()}
  def init(opts) do
    # let's start our animation manager. The manager makes sure only one will be started
    if Keyword.get(opts, :dont_start, false) do
      :ok
    else
      Manager.start_link(opts)
    end
  end

  def create_job(name, pattern, options, function) do
    %{
      name => %{
        type: :job,
        pattern: pattern,
        options: options,
        func: function
      }
    }
  end

  @spec ast_extract_configs(Macro.t()) :: Macro.t()
  def ast_extract_configs(block) do
    {_ast, configs_ast} =
      Macro.prewalk(block, [], fn
        {type, meta, children}, acc when type in @fledex_macros ->
          {nil, [{type, meta, children} | acc]}

        # list, acc when is_list(list) ->
        #   {nil, list ++ acc}
        other, acc ->
          {other, acc}
      end)

    configs_ast
  end

  def ast_add_argument_to_func(block) do
    case block do
      [{:->, _, _}] -> raise ArgumentError, "No argument expected"
      block -> ast_add_argument_to_func_if_missing(block)
    end
  end

  def ast_add_argument_to_func_if_missing(block) do
    case block do
      # argument matched, create only an anonymous function around it
      [{:->, _metadata, _context} | _tail] = block -> ast_create_anonymous_func(block)
      # argument didn't match, create an argument
      # then create an anonymous function around it
      # [{:->, [], [[{:_triggers, [], Elixir}], block]}])
      block -> ast_create_anonymous_func([:_triggers], block)
    end
  end

  @spec ast_create_anonymous_func([{:->, list, [[atom] | any]}]) ::
          {:fn, [], [{:->, list, [[atom] | any]}]}
  def ast_create_anonymous_func([{:->, _, [args, _body]} | _tail] = block) when is_list(args) do
    {:fn, [], block}
  end

  @spec ast_create_anonymous_func([atom], any) :: {:fn, [], [{:->, [], [[atom] | any]}]}
  def ast_create_anonymous_func(args, block) when is_list(args) do
    args =
      Enum.map(args, fn arg ->
        {arg, [], Elixir}
      end)

    {:fn, [], [{:->, [], [args, block]}]}
  end
end
