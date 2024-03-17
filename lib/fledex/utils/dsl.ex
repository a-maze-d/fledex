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

  def create_config(name, type, def_func, options) do
    %{
      name =>
      %{
        type: type,
        def_func: def_func,
        options: options,
        effects: []
      }
    }
  end
  def create_config(name, module, opts) do
    module.configure(name, opts)
  end

  # def apply_effect(module, options, block) do
  #   IO.puts "1) #{inspect module}, 2) #{inspect options}, 3) #{inspect block}"
  # end
  def apply_effect(module, options, block) when is_map(block) do
    IO.puts("start effect1: #{inspect block}")
    apply_effect(module, options, [block])
  end
  def apply_effect(module, options, block) when is_list(block) do
    IO.puts("start effect2: #{inspect block}")
    block
      # merge list of configs
      # |> Map.new()
      |> Enum.reduce(%{}, fn config, acc ->
        Map.merge(acc, config)
      end)
      # add effect to each config
      |> Enum.map(fn {name, config} ->
        {name, %{config | effects: [{module, options} | config.effects]}}
      end)
      |> Map.new()
  end
  def apply_effect(module, options, block) do
    raise "Unknown block. I don't know how to apply the effect #{module} with options #{inspect options} on #{inspect block}"
  end

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

  def init(opts) do
    # let's start our animation manager. The manager makes sure only one will be started
    if not Keyword.get(opts, :dont_start, false) do
      Manager.start_link(@fledex_config)
    end
  end
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
