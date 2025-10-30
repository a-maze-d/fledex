# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Component.Utils do
  @moduledoc """
  Utility functions that are useful when defining components
  """

  @doc """
  A component will have to name their sub-components and needs to ensure
  that the names are unique. This function helps to define a name that
  is composed of the base name (i.e. name of the component), plus the child
  name (i.e. the name of the sub-component).
  """
  @spec create_name(atom, atom) :: atom
  def create_name(base, child) when is_atom(base) and is_atom(child) do
    String.to_atom("#{Atom.to_string(base)}_#{Atom.to_string(child)}")
  end
end
