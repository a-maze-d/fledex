# Copyright 2023-2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Driver.Impl.KinoTest do
  use Kino.LivebookCase, async: true

  require Logger

  alias Fledex.Color.Correction
  alias Fledex.Driver.Impl.Kino

  describe "null driver basic tests" do
    test "default init" do
      config = Kino.init([], %{})
      assert Keyword.fetch!(config, :update_freq) == 1
      assert Keyword.fetch!(config, :frame) != nil
      assert Keyword.fetch!(config, :color_correction) == Correction.no_color_correction()
    end

    test "reinit" do
      config = Kino.init([], %{})
      config_reinit = Kino.reinit(config, [], %{})
      assert Keyword.fetch!(config, :frame) != Keyword.fetch!(config_reinit, :frame)
    end

    test "transfer" do
      config = Kino.init([], %{})
      leds = [0xFF0000, 0x00FF00, 0x0000FF]
      {response_config, _response_other} = Kino.transfer(leds, 0, config)
      assert response_config == config

      assert_output(%{
        type: :frame_update,
        update: {
          :replace,
          [
            %{
              chunk: false,
              text:
                "<span style=\"color: #FF0000\">█</span><span style=\"color: #00FF00\">█</span><span style=\"color: #0000FF\">█</span>",
              type: :markdown
            }
          ]
        }
      })
    end

    test "terminate" do
      assert Kino.terminate(:normal, %{}) == :ok
    end
  end
end
