# Copyright 2024-2026, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Utils.Dsl do
  @moduledoc """
  The module is only inteded to be used by the Fledex module.

  It's a set of helper functions to create the DSL. A lot of functions are workign on
  the AST (abstract syntax tree) level.
  """

  # require Logger

  alias Fledex.Animation.Coordinator
  alias Fledex.Animation.JobScheduler
  alias Fledex.Animation.Manager
  alias Fledex.Application
  alias Fledex.Leds
  alias Fledex.LedStrip
  alias Fledex.Scheduler.Job
  alias Fledex.Supervisor.AnimationSystem

  @fledex_macros [
    :animation,
    :static,
    :job,
    :coordinator,
    :component,
    :effect
  ]

  @doc """
  This function creates a configuration for an animator
  """
  @spec create_config(atom, :animation | :static, (map -> Leds.t()), keyword | nil) ::
          Manager.config_t()
  def create_config(name, type, def_func, options)
      when is_atom(name) and (type == :animation or type == :static) and
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

  @doc """
  This function creates the configuration for a component
  """
  @spec create_config(atom, atom, keyword | nil) :: Manager.config_t()
  def create_config(name, module, opts) do
    module.configure(name, opts)
  end

  @doc """
  This function applies an effect to some configurations
  """
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

  @doc """
  This function creates the configuration for an led strip
  """
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
        DynamicSupervisor.start_child(
          Application.app_supervisor(),
          AnimationSystem.child_spec(opts)
        )

      :kino ->
        Kino.start_child(AnimationSystem.child_spec(opts))

      {:dynamic, name} ->
        DynamicSupervisor.start_child(name, AnimationSystem.child_spec(opts))

        # {:module, module} ->
        #   module.start_link(AnimationSystem.child_spec(opts))
    end
  end

  @doc """
  This function creates the confguration for a job
  """
  @spec create_job(atom, Job.schedule(), keyword, (-> any())) :: %{
          atom => JobScheduler.config_t()
        }
  def create_job(name, schedule, options, function) do
    %{
      name => %{
        type: :job,
        schedule: schedule,
        options: options,
        func: function
      }
    }
  end

  @doc """
  This function creates the configuration for a coordinator
  """
  @spec create_coordinator(atom, keyword, (-> any())) :: %{atom => Coordinator.config_t()}
  def create_coordinator(name, options, function) do
    %{
      name => %{
        type: :coordinator,
        options: options,
        func: function
      }
    }
  end

  @doc """
  This function extracts teh configs from an AST
  """
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
end
