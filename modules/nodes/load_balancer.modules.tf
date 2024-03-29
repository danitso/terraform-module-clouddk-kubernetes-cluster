/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module "load_balancer_server_selector" {
  source = "github.com/danitso/terraform-module-clouddk-server-selector"

  server_memory     = max(var.load_balancer_memory, 512)
  server_processors = max(var.load_balancer_processors, 1)
}
