defmodule Fledex.Utils.Naming do
  @doc """
    This function will create an atomic name for the combination of strip name and
    animation name. This is used to name the animator. The animator does need to
    adhere to this naming convention to properly be shut down.
  """
  @spec build_strip_animation_name(atom, atom) :: atom
  def build_strip_animation_name(strip_name, animation_name)
    # TODO: we migth want to move this to a module that captures the base functionality
    # that all animators share. But it's ok to have it here
    when is_atom(strip_name) and is_atom(animation_name) do
    String.to_atom("#{strip_name}_#{animation_name}")
  end
end
