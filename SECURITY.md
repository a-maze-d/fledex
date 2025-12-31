<!--
Copyright 2023, Matthias Reik <fledex@reik.org>

SPDX-License-Identifier: Apache-2.0
-->

# Security Policy

## Supported Versions

Even though security issues are quite unlikely in this library, if issues
are discovered, I'm happy to fix those (as far as reasonablly possible). 
Currently only the latest version is supported

## Reporting a Vulnerability

If you think you found a vulnerability and want to report it, then send an
email to fledex at reik.org

## Known issues
The library works extensively with atoms and creates them if necessary on
the fly. This could lead to a DDS attack.

This is a known issue and concern and the user of the library needs
to ensure that this can not be abused.