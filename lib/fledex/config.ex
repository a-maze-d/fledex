# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Config do
  @moduledoc """
  > #### Caution {:.warning}
  >
  > Even though you can `use` this module several times, you might get unwanted
  > effects and change your `Fledex.Config.Data` unintentionally.
  > You really should just call `create_config/1` in this module only once.
  >
  > When you `use Fledex` you will also call `create_config/1`. In a `component` you
  > should not `use Fledex` but `import Fledex` and be explicit in your color selection.
  """

  alias Fledex.Color.Names.Utils

  @doc """
  By using this module you configure the Fledex. Currently the only setting is to define
  the color modules to be used through the `:colors` option.

  > #### Caution {:.warning}
  >
  > This will create the `Fledex.Config.Data` module. If you `use` this
  > module several times, previous definition will be replaced. This could lead
  > to unexpected behaviors.

  ### Options:
  * `:colors`: You can specify a single color module, a list of color modules, or one of the special specifiers (`:default`, `:all`, `:none`, `nil`). When you specify a color module you can do so either through it's fully qualified module name (and thereby even
  load color modules that Fledex doesn't know about) or through its shortcut name (see `Fledex.Config.modules/0`)

  ### Special specifiers:
  * `:all`: All known color modules will be loaded. Be careful, because there are A LOT of color names, probably more than what you really need
  * `:default`: This will load the core modules (see `Fledex.Config.modules/0`). If no `:colors` option is specified then that's also the set that will be loaded.
  * `:none`: No color will be loaded (still the `Fledex.Color.Names.Config` will be created. Compare this with `nil`)
  * `nil`: This is similar to `:none` except that the `Fledex.Color.Names.Config` will not be created, and if it exists will be deleted.
  """
  defmacro __using__(opts) do
    create_config_ast(opts)
  end

  @doc """
  check whether we have defined a configuration. If not, all function calls
  will succeed, but return quite empty results
  """
  def exists?() do
    Code.loaded?(Fledex.Config.Data)
  end

  @doc """
  Get the list of modules and their (non-overlapping) colors that are currently configured
  """
  @spec colors :: list({module, list(atom)})
  def colors do
    case exists?() do
      true ->
        # credo:disable-for-next-line
        apply(Fledex.Config.Data, :colors, [])

      false ->
        []
    end
  end

  def create_config_ast(opts) do
    colors = Keyword.get(opts, :colors, :default)
    mod_name = Fledex.Config.Data

    if colors == nil do
      quote bind_quoted: [mod_name: mod_name] do
        if Code.loaded?(mod_name) do
          # `Code` does not expose those functions, so we need to use Erlang version.
          :code.purge(mod_name)
          :code.delete(mod_name)
        end
      end
    else
      # we get an AST, so we need to convert it back to a list of atoms and module names
      modules_and_colors =
        colors
        |> Macro.prewalk(&Macro.expand(&1, __ENV__))
        |> Utils.find_modules_with_names()

      ast = Utils.create_imports_ast(modules_and_colors)

      quote bind_quoted: [mod_name: mod_name, colors: modules_and_colors, ast: ast] do
        Macro.escape(ast)

        if Code.loaded?(mod_name) do
          # `Code` does not expose those functions, so we need to use Erlang version.
          :code.purge(mod_name)
          :code.delete(mod_name)
        end

        defmodule mod_name do
          @moduledoc """
          This module is an implementation detail from `Fledex.Color.Names` and therefore
          should not be used directly. use `Fledex.Config.colors/0` instead
          """
          @colors colors

          @doc false
          @spec colors :: list({module, list(atom)})
          def colors do
            @colors
          end
        end
      end
    end
  end
end
