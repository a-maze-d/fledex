# Copyright 2024, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

import Mox
defmock(Fledex.MockJobScheduler, for: Fledex.Animation.JobScheduler)
defmock(Fledex.MockCoordinator, for: Fledex.Animation.Coordinator)
