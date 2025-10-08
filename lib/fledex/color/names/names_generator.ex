# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fledex.Color.NamesGenerator do
  @moduledoc """
  This module is responsible for creating the `Fledex.Color.Names` module
  that is used as interface towards other color modules.
  This is used and there is probably no reason to call it directly.
  > #### Caution {:.warning}
  >
  > If you are not careful you might generate this module several times
  > which might lead to conflicts, warnings, ... . Once the module is
  > defined you can't "undefine" it.

  See [`__using__/1`](`__using__/1`) for more details
  """

  require Logger

  # I think the documentation is not picking up the
  # behaviour if we use the alias before the behaviour
  # alias Fledex.Color.Names.Interface
  # alias Fledex.Color.Names.Types

  # List of modules that define colors that should be loaded
  # Note: if there is an overlap between the lists, i.e. the same color name
  #       appears twice, then only the first definition will be used.
  #       Thus, the different color modules should be sorted accordingly
  #       You can still call the alternative color definition by going
  #       to the defining module directly.
  # Note2: Each color module can be of type `:core` and therefore will be included
  #       in the Fledex.Color.Names module or of tpe `:optional` which can still
  #       be used through the `Fledex.Color` protocol by calling:
  #       to_colorint(some_atom), which will also be looked up in optional
  #       color modules
  # @modules [
  #   {Fledex.Color.Names.Wiki, :core, :wiki},
  #   {Fledex.Color.Names.CSS, :core, :css},
  #   {Fledex.Color.Names.SVG, :core, :svg},
  #   # we intentionally do not include RAL colors as `:core`
  #   {Fledex.Color.Names.RAL, :optional, :ral}
  # ]

  @doc """
  This module allows to define a single interface for several color modules
  Instead of importing this module use `use #{__MODULE__}` instead.

  This allows  to control which color name spaces (and in which order)
  get imported.

  > #### Note {: .info}
  >
  > If no colors are defined (i.e. `colors: []` is specified), then nothing will
  > be created.
  """
  @spec __using__(keyword) :: Macro.t()
  defmacro __using__(opts \\ []) do
    color_mod_name_defined = Keyword.get(opts, :color_mod_name_defined)
    color_mod_name = Keyword.get(opts, :color_mod_name, nil)
    colors = Keyword.get(opts, :colors, [])

    if Enum.empty?(colors) or (color_mod_name_defined and color_mod_name == nil) do
      nil
    else
      color_mod_name = color_mod_name || Fledex.Color.Names

      quote bind_quoted: [colors: colors, color_mod_name: color_mod_name] do
        defmodule color_mod_name do
          alias Fledex.Color.Names.Types
          @modules_and_colors colors

          @doc guard: true
          defguard is_color_name(atom) when is_atom(atom)

          @spec names :: list(Types.color_name_t())
          def names do
            Enum.flat_map(@modules_and_colors, fn {_module, colors} -> colors end)
          end

          def find_module_with_names(name) do
            module_and_names =
              Enum.find(@modules_and_colors, {nil, []}, fn {module, colors} ->
                name in colors
              end)
          end

          # defp find_name_in_colors?(colors, name) do
          #   name in colors
          #   # Enum.find(colors, fn color -> color == name end) != nil
          # end

          def info(name, what \\ :hex)

          def info(name, what) do
            module =
              find_module_with_names(name)
              |> elem(0)

            case module != nil and function_exported?(module, name, 1) do
              true -> apply(module, name, [what])
              false -> nil
            end
          end

          def modules_and_colors do
            @modules_and_colors
          end
        end
      end
    end
  end
end
