# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

import Config

config :logger, level: :info
config :fledex, Fledex.Animation.JobScheduler, debug_logging: false

import_config "config_#{Mix.env()}.exs"
