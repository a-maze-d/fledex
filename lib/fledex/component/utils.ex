# Copyright 2024-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Component.Utils do
  @spec create_name(atom, atom) :: atom
  def create_name(base, child) when is_atom(base) and is_atom(child) do
    String.to_atom("#{Atom.to_string(base)}_#{Atom.to_string(child)}")
  end
end
