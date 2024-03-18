# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Utils.Dsl do
  alias Fledex.Animation.Animator
  alias Fledex.Animation.Manager

  @fledex_config %{
    animation: Animator,
    static: Animator,
    component: Animator, # This is not the correct one yet
    effect: Animator # This is not yet correct. It shouldn't appear here at all, but it makes it work for now
  }
  @fledex_config_keys Map.keys(@fledex_config)

  @spec create_config(atom, atom, (map -> Leds.t), keyword | nil) :: Manager.config_t()
  def create_config(name, type, def_func, options) when
    is_atom(name) and is_atom(type) and (is_function(def_func, 1) or is_function(def_func, 2))
  do
    %{
      name =>
      %{
        type: type,
        def_func: def_func,
        options: options || [],
        effects: []
      }
    }
  end
  @spec create_config(atom, atom, keyword | nil) :: Manager.config_t
  def create_config(name, module, opts) do
    module.configure(name, opts)
  end

  @spec apply_effect(atom, keyword, Manager.config_t() | [Manager.config_t()]) :: Manager.config_t()
  def apply_effect(module, options, block) when
    is_atom(module) and is_list(options) and is_map(block)
  do
    apply_effect(module, options, [block])
  end
  def apply_effect(module, options, block) when
    is_atom(module) and is_list(options) and is_list(block)
  do
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
    raise ArgumentError, "Unknown block. I don't know how to apply the effect #{module} with options #{inspect options} on #{inspect block}"
  end

  @spec configure_strip(atom, atom | keyword, [Manager.config_t] | Manager.config_t) :: :ok | Manager.config_t
  def configure_strip(strip_name, strip_options, config) when is_list(config) do
    config = Enum.reduce(config, %{}, fn map, acc ->
      Map.merge(acc, map)
    end)
    configure_strip(strip_name, strip_options, config)
  end
  def configure_strip(strip_name, strip_options, config) do
    if is_atom(strip_options) and strip_options == :debug do
      config
    else
      Manager.register_strip(strip_name, strip_options)
      Manager.register_animations(strip_name, config)
    end
  end

  @spec init(keyword) :: :ok | {:ok, pid()}
  def init(opts) do
    # let's start our animation manager. The manager makes sure only one will be started
    if Keyword.get(opts, :dont_start, false) do
      :ok
    else
      Manager.start_link(@fledex_config)
    end
  end
  @spec extract_configs(Macro.t) :: Macro.t
  def extract_configs(block) do
    {_ast, configs_ast} = Macro.prewalk(block, [], fn
      {type, meta, children}, acc when type in @fledex_config_keys ->
        {nil, [{type, meta, children} | acc]}
      # list, acc when is_list(list) ->
      #   {nil, list ++ acc}
      other, acc ->
        {other, acc}
    end)
    configs_ast
  end
end
