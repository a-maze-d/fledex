# Copyright 2025, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

# For now we are not strict
%{
  __struct__: Doctor.Config,
  exception_moduledoc_required: true,
  moduledoc_required: nil,
  failed: false,
  # Doctor has issues with the code generation and counting it's documentation
  ignore_modules: [Fledex.Color.Names.ModuleGenerator],
  ignore_paths: [],
  min_module_doc_coverage: 100,
  min_module_spec_coverage: 100,
  min_overall_doc_coverage: 100,
  min_overall_moduledoc_coverage: 100,
  min_overall_spec_coverage: 100,
  raise: true,
  reporter: Doctor.Reporters.Summary,
  struct_type_spec_required: true,
  umbrella: false
}
