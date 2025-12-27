# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

import Config

config :logger, level: :info

import_config "config_#{Mix.env()}.exs"
