/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module "node_server_selector" {
  source = "github.com/danitso/terraform-module-clouddk-server-selector"

  server_memory     = max(var.node_memory, 2048)
  server_processors = max(var.node_processors, 1)
}
