# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Utils.Dsl do
  @moduledoc """
  The module is only inteded to be used by the Fledex module.

  It's a set of helper functions to create the DSL. A lot of functions are workign on
  the AST (abstract syntax tree) level.
  """
  require Logger

  alias Fledex.Animation.Manager
  alias Fledex.Leds
  alias Fledex.LedStrip
  alias Fledex.Supervisor.AnimationSystem

  @fledex_macros [
    :animation,
    :static,
    :job,
    :coordinator,
    :component,
    :effect
  ]

  @spec create_config(atom, atom, (map -> Leds.t()), keyword | nil) :: Manager.config_t()
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

  @spec create_config(atom, atom, keyword | nil) :: Manager.config_t()
  def create_config(name, module, opts) do
    module.configure(name, opts)
  end

  @spec apply_effect(atom, keyword, Manager.config_t() | [Manager.config_t()]) ::
          Manager.config_t()
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
          :config | LedStrip.drivers_config_t(),
          keyword,
          [Manager.config_t()] | Manager.config_t()
        ) :: :ok | Manager.config_t()
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
    Manager.register_strip(strip_name, drivers, strip_options)
    Manager.register_config(strip_name, config)
  end

  @doc """
  This initializes our animation system, except if we don't want this
  """
  @spec init(keyword) :: :ok | {:ok, pid()}
  def init(opts) do
    # let's start our animation manager. The manager makes sure only one will be started
    if Keyword.get(opts, :dont_start, false) == true do
      :ok
    else
      # Logger.info("Starting AnimationSystem with: #{inspect opts}")
      case start_system(opts) do
        {:ok, pid} ->
          {:ok, pid}

        {:error, {:already_started, pid}} ->
          {:ok, pid}
          # other -> other
      end
    end
  end

  defp start_system(opts) do
    log_level = Keyword.get(opts, :log_level, :info)
    supervisor = Keyword.get(opts, :supervisor, :none)
    opts = Keyword.drop(opts, [:supervisor, :log_level])

    Logger.configure(level: log_level)

    case supervisor do
      :none ->
        AnimationSystem.start_link(opts)

      :app ->
        DynamicSupervisor.start_child(Fledex.DynamicSupervisor, AnimationSystem.child_spec(opts))

      :kino ->
        Kino.start_child(AnimationSystem.child_spec(opts))

      {:dynamic, name} ->
        DynamicSupervisor.start_child(name, AnimationSystem.child_spec(opts))

        # {:module, module} ->
        #   module.start_link(AnimationSystem.child_spec(opts))
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

  def create_coordinator(name, options, function) do
    %{
      name => %{
        type: :coordinator,
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

  @doc """
  This function takes an ast function block and adds an argument
  to the function. This is different from `ast_add_argument_to_func_if_missing/1`
  that it does not expect there to be an arugment and therefore will raise an
  `ArgumentError` if it does find one.
  """
  @spec ast_add_argument_to_func(any()) :: {:fn, [], [{:->, list(), list()}, ...]}
  def ast_add_argument_to_func(block) do
    case block do
      [{:->, _func, _args}] -> raise ArgumentError, "No argument expected"
      block -> ast_add_argument_to_func_if_missing(block)
    end
  end

  @doc """
  This function takes an AST block of a function, checks whether
  the required parameter (`trigger`) is present, and if not will
  add one.
  This function is to decide on whether `ast_create_anonymous_func/1`
  or `ast_create_anonymous_func/2` should be called

  > #### Note {: .info}
  >
  > This function makes the assumption that a single argument is required.
  """
  @spec ast_add_argument_to_func_if_missing(any()) :: {:fn, [], [{:->, list(), list()}, ...]}
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

  @doc """
    This function takes an AST of a function body and wraps it into
    an anonymous function.
    It does expect that the arguments are handled as part of the function
    body, e.g. the function body should look something like this:

    ```elixir
    arg1 -> :ok
    arg1, arg2 -> :ok
    ```
  """
  @spec ast_create_anonymous_func([{:->, list, [[atom] | any]}]) ::
          {:fn, [], [{:->, list, [[atom] | any]}]}
  def ast_create_anonymous_func([{:->, _func, [args, _body]} | _tail] = block)
      when is_list(args) do
    {:fn, [], block}
  end

  @doc """
   This function is similar to `ast_create_anonymous_func/1`, except that no
   argument was specified in the block (because the user does not want to use it),
   even though the function should have one.
   The function will make sure to add the argument to the block before wrapping
   it into an anonymous function.
  """
  @spec ast_create_anonymous_func([atom], any) :: {:fn, [], [{:->, [], [[atom] | any]}]}
  def ast_create_anonymous_func(args, block) when is_list(args) do
    args =
      Enum.map(args, fn arg ->
        {arg, [], Elixir}
      end)

    {:fn, [], [{:->, [], [args, block]}]}
  end

  @modules [
    {Fledex.Color.Names.Wiki, :core, :wiki},
    {Fledex.Color.Names.CSS, :core, :css},
    {Fledex.Color.Names.SVG, :core, :svg},
    # we intentionally do not include RAL colors as `:core`
    {Fledex.Color.Names.RAL, :optional, :ral}
  ]

  @doc """
  This function creates the ASTs for using and for importing
  the necessary color name modules
  The returned options are the original as the one passed in
  but with all the consumed options removed.
  """
  @spec create_color_name_asts(keyword) ::
          {use_ast :: Macro.t(), import_ast :: Macro.t(), keyword}
  def create_color_name_asts(opts) do
    color_mod_name_defined = Keyword.has_key?(opts, :color_mod_name)
    color_mod_name = opts[:color_mod_name]
    modules_with_names = find_modules_with_names(opts[:colors])
    opts = Keyword.drop(opts, [:colors, :color_mod_name])

    modules_with_only = modules_with_only(modules_with_names)
    import_ast = Enum.map(modules_with_only, &import_color_module/1)
    # for some reason it doesn't work to have
    # quote do
    #   use Fledex.Color.Names, colors: unquote(colors)
    # end
    use_ast = {
      :use,
      [
        context: Elixir,
        imports: [{1, Kernel}, {2, Kernel}]
      ],
      [
        {:__aliases__, [alias: false], [:Fledex, :Color, :NamesGenerator]},
        [
          colors: modules_with_names,
          color_mod_name: color_mod_name,
          color_mod_name_defined: color_mod_name_defined
        ]
      ]
    }

    {use_ast, import_ast, opts}
  end

  @spec import_color_module({module, list(atom)}) :: Macro.t()
  defp import_color_module({module, only}) do
    # for some reason it doesn't work to do
    # quote do
    #   import unquote(module), only: unquote(only)
    # end
    # Therefore creating the AST manually
    module_alias_ast =
      quote do
        unquote(module)
      end

    {:import, [context: Elixir],
     [
       module_alias_ast,
       [only: only]
     ]}
  end

  @doc """
  Convert a list of module-only list to a list that
  can be used to import modules
  """
  @spec modules_with_only(list({module, list(atom)})) :: list({module, list({atom, 0 | 1 | 2})})
  def modules_with_only(modules_with_names) do
    # each name has a function with arity 1 and 2
    Enum.map(modules_with_names, fn {module, names} ->
      {module,
       Enum.flat_map(names, fn only ->
         [{only, 0}, {only, 1}, {only, 2}]
       end)}
    end)
  end

  @doc """
  This function takes either a module, an atom or a list of those,
  resolves atoms to their corresponding modules, retrieves all
  the color names by calling `module.names()` ensuring later modules
  do not override previous names in case of conflict, and returns
  a list of modules and their non-conflicting names.
  """
  @spec find_modules_with_names(module | atom | list(module | atom) | nil) ::
          list({module, list(atom)})
  def find_modules_with_names([]), do: []
  def find_modules_with_names(nil), do: find_modules_with_names([:default])
  def find_modules_with_names(opt) when is_atom(opt), do: find_modules_with_names([opt])
  def find_modules_with_names([:none]), do: find_modules_with_names([])

  def find_modules_with_names([:all]) do
    Enum.map(@modules, fn elem -> elem(elem, 0) end)
    |> find_modules_with_names()
  end

  def find_modules_with_names([:default]) do
    Enum.filter(@modules, fn {_mod, type, _name} -> type == :core end)
    |> Enum.map(fn elem -> elem(elem, 0) end)
    |> find_modules_with_names()
  end

  def find_modules_with_names(color_names) when is_list(color_names) do
    color_names
    # |> Enum.reverse()
    |> translate_names2modules()
    |> diff_names_between_modules()
  end

  @spec translate_names2modules(list(module | atom)) :: list(module)
  defp translate_names2modules(names) do
    Enum.reduce(names, [], fn color_name, acc ->
      find_module_name(color_name, acc)
    end)
    |> Enum.reverse()
  end

  @spec find_module_name(atom | module, list(module)) :: list(module)
  defp find_module_name(color_name, acc) do
    case Enum.find(@modules, fn {_module, _type, name} -> name == color_name end) do
      {module, _type, _name} ->
        # we translate from an atom to a module
        [module | acc]

      nil ->
        # no translation, maybe we got a names module
        if loadable?(color_name) do
          [color_name | acc]
        else
          # we have no idea what we got so we will ignore it
          Logger.warning("""
          Not a known color name. Either an atom (with appropriate mapping)
          or a module (implementing the Fledex.ColorNames behavior) is expected.
          I found instead: #{inspect(color_name)}
          And we will ignore it
          """)

          acc
        end
    end
  end

  @spec loadable?(module) :: boolean
  defp loadable?(color_name) do
    Code.ensure_loaded?(color_name) and function_exported?(color_name, :names, 0)
  end

  @spec diff_names_between_modules(list(module)) :: list({module, list(atom)})
  defp diff_names_between_modules(modules) do
    Enum.reduce(modules, {[], MapSet.new()}, fn module, {mods, known} ->
      only = MapSet.difference(MapSet.new(module.names()), known)
      {[{module, MapSet.to_list(only)} | mods], MapSet.union(known, only)}
    end)
    |> elem(0)
    |> Enum.reverse()
  end
end
