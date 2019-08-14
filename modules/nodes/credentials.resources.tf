/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

resource "random_string" "root_password" {
  length = 64

  min_lower   = 1
  min_numeric = 1
  min_upper   = 1

  special = false
}
