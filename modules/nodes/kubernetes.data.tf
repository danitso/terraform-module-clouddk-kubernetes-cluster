/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

data "sftp_remote_file" "kubernetes_token" {
  count = "${var.master ? 1 : 0}"

  allow_missing = true

  host        = element(flatten(clouddk_server.node[0].network_interface_addresses), 0)
  user        = "root"
  private_key = tls_private_key.private_ssh_key.private_key_pem

  path = "/etc/kubernetes/token.txt"

  triggers = {
    init_id = element(concat(null_resource.kubernetes_service_account.*.id, list("")), 0)
  }
}
