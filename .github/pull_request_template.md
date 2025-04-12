<!--
Copyright 2023-2024, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

<!--- Summary of your changes in the Title above --->

## Detail description of your changes
<!--- Provide a detailed description of your changes
including motivation and background --->

## Issue ticket number and link
<!--- not requried for some simple typo corrections --->

## Type of change

Please delete options that are not relevant.

- [ ] Fixing documentation typo(s)
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## Checklist before requesting a review
- [ ] I performed a self-review of my code
- [ ] I run `mix format`
- [ ] I run `mix compile` and it compiles without errors or warnings
- [ ] I run `mix test` or `mix coveralls.html` and have **100%** code coverage (and if not I explained below why)
- [ ] I run `mix credo` and no issues (that weren't there before) were found.
- [ ] I specified all functions with a type `@spec`
- [ ] I run `mix dialyzer` and no issues were found
- [ ] I added module and function documentation to all my public modules/functions
- [ ] I run `mix docs` and no issues were found
- [ ] I run `mix xref graph --label compile-connected --fail-above 18` or explain why you will need to increase it.
- [ ] I run through the different `livebook/`s to ensure that they all work.
- [ ] I added a new livebook (or modified an exisitng one)  to explain the new functionality (only applies for major functionality)
- [ ] I run `mix reuse` (or `pipx run reuse lint`) and fixed all issues
