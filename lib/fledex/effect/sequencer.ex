# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Effect.Sequencer do
  @behaviour Fledex.Effect.Interface

  @impl true
  def apply(leds, count, config, triggers) do
    modules = Keyword.fetch!(config, :modules)
    sequences = Keyword.fetch!(config, :sequences)
    trigger_name = Keyword.fetch!(config, :trigger_name)
    _repetitions = Keyword.get(config, :repeat, 1)
    _round = triggers[String.to_atom("#{trigger_name}.round")] || 0

    current_sequence = get_current_sequence(triggers, trigger_name)
    {module, module_config} = get_module(modules, current_sequence)
    {leds, triggers, effect_state} = module.apply(leds, count, module_config, triggers)

    {triggers, effect_state} =
      set_next_sequence(sequences, triggers, trigger_name, current_sequence, effect_state)

    {leds, triggers, effect_state}
  end

  defp get_current_sequence(triggers, trigger_name) do
    triggers[trigger_name] || {0, 0}
  end

  @spec get_module([{module, keyword}], {pos_integer, pos_integer | nil}) ::
          {module, keyword} | nil
  defp get_module(modules, {_sequence_id, module_index} = _current_sequence) do
    Enum.at(modules, module_index)
  end

  defp set_next_sequence(
         sequences,
         triggers,
         trigger_name,
         {sequence_id, _module_index} = _current_sequence,
         effect_state
       ) do
    case effect_state do
      state when state == :stop_start or state == :stop ->
        sequence_id = sequence_id + 1
        module_index = Enum.at(sequences, sequence_id, nil)
        {%{triggers | trigger_name => {sequence_id, module_index}}, :progress}

      _state ->
        {triggers, :progress}
    end
  end
end
