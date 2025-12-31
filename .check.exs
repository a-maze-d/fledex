# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

[
  ## don't run tools concurrently
  # parallel: false,

  ## don't print info about skipped tools
  skipped: false,

  ## always run tools in fix mode (put it in ~/.check.exs locally, not in project config)
  # fix: true,

  ## don't retry automatically even if last run resulted in failures
  # retry: false,

  ## list of tools (see `mix check` docs for a list of default curated tools)
  tools: [
    ## curated tools may be disabled (e.g. the check for compilation warnings)
    # {:compiler, false},

    ## ...or have command & args adjusted (e.g. enable skip comments for sobelow)
    {:sobelow, "mix sobelow --config"},

    ## ...or reordered (e.g. to see output from dialyzer before others)
    # {:dialyzer, order: -1},

    ## ...or reconfigured (e.g. disable parallel execution of ex_unit in umbrella)
    # {:ex_unit, umbrella: [parallel: false]},

    ## custom new tools may be added (Mix tasks or arbitrary commands)
    # {:my_task, "mix my_task", env: %{"MIX_ENV" => "prod"}},
    # {:my_tool, ["my_tool", "arg with spaces"]}

    # my changes
    {:ex_doc, enabled: false},
    {:ex_unit, enabled: false},
    {:doc, "mix docs", env: %{"MIX_ENV" => "dev"}},
    {:reuse, "mix reuse", env: %{"MIX_ENV" => "dev"}},
    {:xref, "mix xref graph --label compile-connected --fail-above 7", env: %{"MIX_ENV" => "dev"}},
    {:coveralls, "mix coveralls.multiple --type html --type json", env: %{"MIX_ENV" => "test"}},
  ]
]
