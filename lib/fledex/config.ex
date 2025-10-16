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

  defp exists?() do
    Code.loaded?(Fledex.Config.Data)
  end

    @doc """
  Get the list of modules and their (non-overlapping) colors that are currently configured
  """
  @spec modules_and_colors :: list({module, list(atom)})
  def modules_and_colors do
    case exists?() do
      true ->
        # credo:disable-for-next-line
        apply(Fledex.Config.Data, :modules_and_colors, [])

      false ->
        []
    end
  end

  def create_config(opts) do
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

      quote bind_quoted: [mod_name: mod_name, modules_and_colors: modules_and_colors, ast: ast] do
        Macro.escape(ast)

        if Code.loaded?(mod_name) do
          # `Code` does not expose those functions, so we need to use Erlang version.
          :code.purge(mod_name)
          :code.delete(mod_name)
        end

        defmodule mod_name do
          @moduledoc """
          This module is an implementation detail from `Fledex.Color.Names` and therefore
          should not be used directly. use `Fledex.Color.Names.modules_and_colors/0` instead
          """
          @modules_and_colors modules_and_colors

          @doc false
          @spec modules_and_colors :: list({module, list(atom)})
          def modules_and_colors do
            @modules_and_colors
          end
        end
      end
    end
  end
end
