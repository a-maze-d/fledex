<!-- usage-rules-start -->
<!-- ex_check-start -->
## ex_check usage
_ex_check_

# ex_check usage rules

ex_check provides the `mix check` task: it runs all of a project's code analysis &
testing tools (compiler, formatter, credo, dialyzer, tests, security scanners, ...) in
parallel with one command, and reports every failure in a single run.

## Running

```
mix check
```

Runs every detected tool. Tools whose package or required files are absent are skipped
automatically — you do not need to configure them. Exit status is non-zero if any tool
fails.

For machine-readable output:

```
mix check --format agent                     # for agents: JSON status header + raw failure blocks
mix check --format json --output check.json  # for CI and tooling: one JSON document
```

Both formats include a `diagnostics` list for failed `compiler`/`credo`/`ex_unit` checks —
each entry has `file`, `line` and `message`, so you can jump straight to a finding instead
of parsing the raw output blocks.

## Useful flags

- `--only NAME` / `-o NAME` — run only the named tool(s); repeatable. e.g. `mix check -o credo -o ex_unit`
- `--except NAME` / `-x NAME` — skip the named tool(s); repeatable.
- `--fix` / `-f` — auto-fix what can be fixed (e.g. `mix format`, unlock unused deps).
- `--retry` / `-r` — run only tools that failed in the previous run.
- `--no-parallel` — run tools sequentially.
- `--halt-on-failure` — don't start further tools once one has failed (best with `--no-parallel`).
- `--config PATH` / `-c PATH` — use a specific config file.
- `--format pretty|agent|json|github|junit` — output format (default `pretty`). `github` emits
  GitHub Actions log groups + a `$GITHUB_STEP_SUMMARY` table; `junit` emits a JUnit XML report.
- `--output PATH` — write the report to a file (only with `--format agent`, `json` or `junit`).

Combine `--fix --retry` to fix only the tools that just failed.

## Configuration: `.check.exs`

Generate a commented starter config:

```
mix check.gen.config
```

`.check.exs` returns a keyword list. Root keys:

- `:tools` — list of tool tuples (overrides/extends the curated set).
- `:fix` — `true` to always run fix mode (default `false`).
- `:parallel` — `false` to disable parallelism (default `true`).
- `:retry` — `false` to disable auto-retry (default: on when a manifest exists).
- `:skipped` — `false` to hide skipped tools in the summary.
- `:halt_on_failure` — `true` to stop starting tools after the first failure (default `false`).

Tool tuple forms:

```elixir
{:credo, false}                              # disable a curated or custom tool
{:credo, "mix credo --strict"}               # override the command
{:my_task, "mix my_task"}                    # add a custom mix task
{:my_tool, ["my_tool", "arg with spaces"]}   # add an arbitrary command
{:npm_test, command: "npm test", cd: "assets", env: %{"CI" => "true"}}
```

Disabling a tool that no config file defines prints a warning and is ignored. Any other tool
without a `:command` (after merging all config files) is an error.

Example `.check.exs`:

```elixir
[
  tools: [
    {:dialyzer, false},
    {:credo, "mix credo --strict"},
    {:my_audit, "mix my_audit"}
  ]
]
```

Local-only overrides go in `~/.check.exs` (e.g. `[fix: true]`). Umbrella projects run
tools recursively per child app by default; tune via each tool's `:umbrella` option.

## Curated tools

`mix check` runs these when detected:

- `compiler` — `mix compile --warnings-as-errors`
- `formatter` — `mix format --check-formatted` (fix: `mix format`)
- `unused_deps` — `mix deps.unlock --check-unused` (fix: `--unused`)
- `hex_audit` — `mix hex.audit` (retired deps & security advisories)
- `credo` — `mix credo`
- `dialyzer` — `mix dialyzer` (needs `:dialyxir`)
- `doctor` — `mix doctor` (needs `:doctor`)
- `ex_doc` — `mix docs` (needs `:ex_doc`)
- `sobelow` — `mix sobelow --exit` (needs `:sobelow`)
- `mix_audit` — `mix deps.audit` (needs `:mix_audit`)
- `gettext` — `mix gettext.extract --check-up-to-date` (needs `:gettext`)
- `knigge` / `ex_knigge` — `mix knigge.verify` (needs `:knigge` or `:ex_knigge`, always runs with `MIX_ENV=dev`)
- `usage_rules` — `mix usage_rules.sync --check` (needs `:usage_rules`; no fix by default, run `mix usage_rules.sync` deliberately)
- `ex_unit` — `mix test` (retry: `mix test --failed`)
- `npm_test` — `npm test` in `assets/` (needs `package.json`)

## Agent guidance

### Do

- Use `mix check --format agent` to verify an Elixir change.
- Read the report from stdout. The first line after `<<<EX_CHECK_REPORT>>>` is a JSON header:

  ```json
  {"status":"error","passed":9,"failed":2,"skipped":4,"duration_s":41.2,
   "failed_checks":["credo","formatter"],
   "diagnostics":[{"check":"credo","file":"lib/foo.ex","line":12,"message":"...","severity":"warning"}]}
  ```

  Raw output for each failed check follows as `=== FAILED: <name> — <command> (exit <code>) ===` blocks.
- Use the raw block when a failed check has no `diagnostics` entry (e.g. `formatter`, `dialyzer`).
- Use `mix check --fix` for formatting and unused deps.
- Use `--only`/`-o` to narrow runs while iterating, and `--retry` to re-run only failures.

### Don't

- Don't redirect `mix check` output to `/dev/null` or pipe it through scripts (`python`, `jq`, `head`).
  A crash before the report is written then goes unnoticed.
- Don't use `--format json --output FILE` to work around agent output. That format is for CI and
  tooling, and a stale file from an earlier run looks like a fresh result.
- Don't truncate the report. If `<<<END_EX_CHECK_REPORT>>>` is missing, the run aborted: read the
  Mix error output instead.
- Don't treat skipped tools as failures. `status` and `failed` only count tools that ran.

<!-- ex_check-end -->
<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

# Rules for working with Igniter

## Understanding Igniter

Igniter is a code generation and project patching framework that enables semantic manipulation of Elixir codebases. It provides tools for creating intelligent generators that can both create new files and modify existing ones safely. Igniter works with AST (Abstract Syntax Trees) through Sourceror.Zipper to make precise, context-aware changes to your code.

## Available Modules

### Project-Level Modules (`Igniter.Project.*`)

- **`Igniter.Project.Application`** - Working with Application modules and application configuration
- **`Igniter.Project.Config`** - Modifying Elixir config files (config.exs, runtime.exs, etc.)
- **`Igniter.Project.Deps`** - Managing dependencies declared in mix.exs
- **`Igniter.Project.Formatter`** - Interacting with .formatter.exs files
- **`Igniter.Project.IgniterConfig`** - Managing .igniter.exs configuration files
- **`Igniter.Project.MixProject`** - Updating project configuration in mix.exs
- **`Igniter.Project.Module`** - Creating and managing modules with proper file placement
- **`Igniter.Project.TaskAliases`** - Managing task aliases in mix.exs
- **`Igniter.Project.Test`** - Working with test and test support files

### Code-Level Modules (`Igniter.Code.*`)

- **`Igniter.Code.Common`** - General purpose utilities for working with Sourceror.Zipper
- **`Igniter.Code.Function`** - Working with function definitions and calls
- **`Igniter.Code.Keyword`** - Manipulating keyword lists
- **`Igniter.Code.List`** - Working with lists in AST
- **`Igniter.Code.Map`** - Manipulating maps
- **`Igniter.Code.Module`** - Working with module definitions and usage
- **`Igniter.Code.String`** - Utilities for string literals
- **`Igniter.Code.Tuple`** - Working with tuples

<!-- igniter-end -->
<!-- sobelow-start -->
## sobelow usage
_Security-focused static analysis for Elixir & the Phoenix framework_

# Sobelow usage rules

Sobelow is a security-focused **static** analyser for Elixir and Phoenix. It reads
source code, never runs it, and never contacts a running application.

## Running it

```sh
mix sobelow                 # scan the current project
mix sobelow -r ../my_app    # scan another project root
```

Add it as a dev/test dependency so `mix sobelow` is available:

```elixir
{:sobelow, "~> 0.14", only: [:dev, :test], runtime: false, warn_if_outdated: true}
```

Sobelow scans **one application at a time**. For an umbrella, add an alias to the
root `mix.exs` and give each child app its own config file:

```elixir
defp aliases do
  [sobelow: ["cmd mix sobelow"]]
end
```

## Confidence levels are triage guidance, not severity

Every finding carries High, Medium, or Low confidence. This is Sobelow's confidence
that the code is *reachable with attacker-controlled input* — not how bad the bug
would be.

- **High** — the tainted value traces back to a function parameter or `conn.params`.
- **Medium** — the dangerous call is present but the input source is less certain.
- **Low** — the pattern looks dangerous but Sobelow cannot tell whether it takes
  user input. Often, but not always, a false positive.

Sobelow intentionally over-reports. **A green (low) finding may still be critical.**
Never tell a user their code is safe because findings are low confidence, and never
suppress low-confidence findings wholesale to make a build pass.

Use `--threshold low|medium|high` to filter the report by confidence.

## Suppressing false positives

There are two mechanisms and they are not interchangeable.

**`# sobelow_skip` comments** mark a *specific function* or a *specific Phoenix
router pipeline*. The comment must sit immediately above the `def` or `pipeline`
it applies to.

```elixir
# sobelow_skip ["Traversal.SendFile", "XSS.Raw"]
def download(conn, params) do
  ...
end
```

On a pipeline they suppress the router configuration checks — `Config.CSRF`,
`Config.Headers`, and `Config.CSP`:

```elixir
# sobelow_skip ["Config.CSRF"]
pipeline :api do
  ...
end
```

Listing the parent `Config` module suppresses every Config check on that
pipeline, the same way `-i Config` ignores the whole group.

Spacing does not matter, but the check names must be a list of double-quoted
strings. A comment Sobelow cannot read is reported on stderr with its file and
line rather than being ignored, so a skip that appears to do nothing is worth
checking the warnings for.

They still cannot suppress configuration findings that are not attached to a
function or a pipeline — `Config.Secrets` or `Config.HTTPS`, for instance, which
come from `config/*.exs`. Use `--mark-skip-all` for those.

**`--mark-skip-all`** writes every currently-reported finding to a `.sobelow-skips`
file, and works for *all* finding types including configuration ones. Use it when
adopting Sobelow on an existing codebase.

Either way, the skips only take effect when you pass `--skip`:

```sh
mix sobelow --mark-skip-all   # record the current findings as accepted
mix sobelow --skip            # scan, ignoring those
mix sobelow --clear-skip      # discard the recorded skips
```

Commit `.sobelow-skips` so the whole team and CI share the same baseline. The file
is rewritten in sorted order each time it is regenerated, so re-running
`--mark-skip-all` after fixing or adding a finding produces a small, readable diff
rather than reshuffling the file. Pass `--legacy-skips` if you need the older
append-only behaviour, which never rewrites lines it did not add.

Prefer `# sobelow_skip` with an explicit module list over `--mark-skip-all` when you
have only a handful of false positives — it documents the decision at the code, and
it does not go stale silently when the line moves.

`--ignore` (`-i`) is different again: it disables a whole check for the entire scan.
Reach for it only when a check does not apply to the project at all.
`--only` is its inverse: `--only XSS.Raw,SQL` runs just those checks (a category name
runs all of its checks). Use it to focus a run, not as a substitute for triage.

## Configuration file

`--save-config` writes a `.sobelow-conf` at the project root from the flags you
passed:

```sh
mix sobelow -i XSS.Raw,Traversal --verbose --exit Low --save-config
```

Precedence rules:

- `.sobelow-conf` is used automatically when present.
- **CLI switches override the file.**
- `--no-config` ignores the file for that run.

The file holds settings only. `--version`, `--details`, `--all-details`,
`--save-config`, and `--diff` pick what Sobelow does instead of configuring a
scan, and each ends the run before one happens, so they are ignored if they
appear in the file.

Commit `.sobelow-conf`. Paths in it are stored relative to the project root, so it
works on other machines and in CI.

## CI

Sobelow exits 0 by default, *even when it finds things*. To fail a build you must
pass `--exit`:

```sh
mix sobelow --exit medium     # non-zero if any medium or high finding exists
mix sobelow --exit            # bare --exit means low, i.e. fail on anything
```

A reasonable starting point for an existing codebase: baseline with
`--mark-skip-all`, then run `mix sobelow --skip --exit low` in CI so any *new*
finding fails the build.

Machine-readable output for other tooling:

```sh
mix sobelow --format json
mix sobelow --format sarif        # e.g. GitHub code scanning
mix sobelow --format sarif --out results.sarif
mix sobelow --format github       # GitHub Actions workflow annotations
```

`--out` implies a machine-readable format; a `txt` format is coerced to `json`.

The `github` format emits warning annotations with confidence levels in the
messages. It uses `GITHUB_WORKSPACE` for repository-relative file locations,
including when a workflow step runs from an application subdirectory.

Other useful flags:

- `--private` — no update check, no network requests, no cache file written.
  Use this in CI and in sandboxed builds.
- `--quiet` — print a one-line count instead of findings.
- `--compact` / `--flycheck` — single-line findings for editors and tooling.
- `--strict` — treat a file Sobelow cannot parse as a hard error (exit 2) instead of
  skipping it. Without it, Sobelow continues with the remaining files and warns
  on stderr. SARIF includes file failures in invocation notifications.
- `--summary` — print file counts on stderr without changing JSON findings.
  Counts cover discovered source/template files and selected configuration
  paths. `scanned` means successfully parsed; `pending` means discovered but
  not parsed by an enabled check. Metadata reads such as dependency mixfiles
  are cached but are not counted as scanned project source.
- `--no-router` — for a project with no Phoenix router, such as a plain Elixir
  library. Without it Sobelow warns that it cannot find one, on every run. The
  router-dependent checks are skipped either way. Set it in `.sobelow-conf` as
  `router: :none`.
- `--include-mix-tasks` — also scan `lib/mix/tasks/`.
- `--include-scripts` — also scan `.exs` under `lib/`, plus source files under
  `scripts/` and `priv/`. These paths are opt-in because many projects use them
  for build-time code rather than request handling.

## What it will and will not find

Sobelow flags patterns, not proven exploits. It has no cross-function taint
tracking: it decides confidence from the parameters of the *enclosing* function
only. A value laundered through a helper will usually come back as low confidence
or not at all.

It also does not check dependencies for known CVEs in general — the `Vuln.*` checks
cover a small fixed set of historical advisories by reading installed dependency
versions or literal Hex versions from `mix.lock`. For real
dependency scanning use `mix hex.audit` (retired packages) alongside a dedicated
tool such as MixAudit.

If Sobelow reports nothing, that is not evidence the application is secure. Say so
plainly rather than reporting a clean scan as a security sign-off.

## Getting details on a finding

```sh
mix sobelow -d Config.CSRF     # explain one check
mix sobelow --all-details      # explain all of them
mix help sobelow               # flags and the full module list
```

<!-- sobelow-end -->
<!-- usage_rules-start -->
## usage_rules usage
_A config-driven dev tool for Elixir projects to manage AGENTS.md files and agent skills from dependencies_

## Using Usage Rules

Many packages have usage rules, which you should *thoroughly* consult before taking any
action. These usage rules contain guidelines and rules *directly from the package authors*.
They are your best source of knowledge for making decisions.

## Modules & functions in the current app and dependencies

When looking for docs for modules & functions that are dependencies of the current project,
or for Elixir itself, use `mix usage_rules.docs`

```
# Search a whole module
mix usage_rules.docs Enum

# Search a specific function
mix usage_rules.docs Enum.zip

# Search a specific function & arity
mix usage_rules.docs Enum.zip/1
```


## Searching Documentation

You should also consult the documentation of any tools you are using, early and often. The best 
way to accomplish this is to use the `usage_rules.search_docs` mix task. Once you have
found what you are looking for, use the links in the search results to get more detail. For example:

```
# Search docs for all packages in the current application, including Elixir
mix usage_rules.search_docs Enum.zip

# Search docs for specific packages
mix usage_rules.search_docs Req.get -p req

# Search docs for multi-word queries
mix usage_rules.search_docs "making requests" -p req

# Search only in titles (useful for finding specific functions/modules)
mix usage_rules.search_docs "Enum.zip" --query-by title
```


<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
# Elixir Core Usage Rules

## Pattern Matching
- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else` or `case` in function bodies
- `%{}` matches ANY map, not just empty maps. Use `map_size(map) == 0` guard to check for truly empty maps

## Error Handling
- Use `{:ok, result}` and `{:error, reason}` tuples for operations that can fail
- Avoid raising exceptions for control flow
- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`

## Common Mistakes to Avoid
- Elixir has no `return` statement, nor early returns. The last expression in a block is always returned.
- Don't use `Enum` functions on large collections when `Stream` is more appropriate
- Avoid nested `case` statements - refactor to a single `case`, `with` or separate functions
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or `Enum` functions
- Prefer `Enum` functions like `Enum.reduce` over recursion
- When recursion is necessary, prefer to use pattern matching in function heads for base case detection
- Using the process dictionary is typically a sign of unidiomatic code
- Only use macros if explicitly requested
- There are many useful standard library functions, prefer to use them where possible

## Function Design
- Use guard clauses: `when is_binary(name) and byte_size(name) > 0`
- Prefer multiple function clauses over complex conditional logic
- Name functions descriptively: `calculate_total_price/2` not `calc/2`
- Predicate function names should not start with `is` and should end in a question mark.
- Names like `is_thing` should be reserved for guards

## Data Structures
- Use structs over maps when the shape is known: `defstruct [:name, :age]`
- Prefer keyword lists for options: `[timeout: 5000, retries: 3]`
- Use maps for dynamic key-value data
- Prefer to prepend to lists `[new | list]` not `list ++ [new]`

## Mix Tasks

- Use `mix help` to list available mix tasks
- Use `mix help task_name` to get docs for an individual task
- Read the docs and options fully before using tasks

## Testing
- Run tests in a specific file with `mix test test/my_test.exs` and a specific test with the line number `mix test path/to/test.exs:123`
- Limit the number of failed tests with `mix test --max-failures n`
- Use `@tag` to tag specific tests, and `mix test --only tag` to run only those tests
- Use `assert_raise` for testing expected exceptions: `assert_raise ArgumentError, fn -> invalid_function() end`
- Use `mix help test` to for full documentation on running tests

## Debugging

- Use `dbg/1` to print values while debugging. This will display the formatted value and other relevant information in the console.

<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
# OTP Usage Rules

## GenServer Best Practices
- Keep state simple and serializable
- Handle all expected messages explicitly
- Use `handle_continue/2` for post-init work
- Implement proper cleanup in `terminate/2` when necessary

## Process Communication
- Use `GenServer.call/3` for synchronous requests expecting replies
- Use `GenServer.cast/2` for fire-and-forget messages.
- When in doubt, use `call` over `cast`, to ensure back-pressure
- Set appropriate timeouts for `call/3` operations

## Fault Tolerance
- Set up processes such that they can handle crashing and being restarted by supervisors
- Use `:max_restarts` and `:max_seconds` to prevent restart loops

## Task and Async
- Use `Task.Supervisor` for better fault tolerance
- Handle task failures with `Task.yield/2` or `Task.shutdown/2`
- Set appropriate task timeouts
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure

<!-- usage_rules:otp-end -->
<!-- usage-rules-end -->
