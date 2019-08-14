/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

locals {
  load_balancer_listener_addresses = ["0.0.0.0"]
  load_balancer_listener_ports     = [6443]
  load_balancer_listener_timeouts  = [300]
  load_balancer_target_addresses   = ["${join(",", flatten(clouddk_server.node.*.network_interface_addresses))}"]
  load_balancer_target_ports       = [6443]
  load_balancer_target_timeouts    = [300]
}
