# Kubernetes Cluster on Cloud.dk

Terraform Module for creating a Kubernetes Cluster on [Cloud.dk](https://cloud.dk)

> **WARNING:** This project is under active development and should be considered alpha.

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) 0.12+
- [Terraform Provider for Cloud.dk](https://github.com/danitso/terraform-provider-clouddk) 0.3+
- [Terraform Provider for SFTP](https://github.com/danitso/terraform-provider-sftp) 0.1+

## Table of contents

- [Creating the cluster](#creating-the-cluster)
- [Accessing the cluster](#accessing-the-cluster)
- [Additional node pools](#additional-node-pools)
- [Installed addons](#installed-addons)
- [Variables](#variables)
    - [Input](#input)
    - [Output](#output)
- [Frequently asked questions](#frequently-asked-questions)
    - [Why are the nodes occasionally rebooting after midnight?](#why-are-the-nodes-occasionally-rebooting-after-midnight)
- [Known issues](#known-issues)
    - [Additional load balancers triggers SSL verification issues](#additional-load-balancers-triggers-SSL-verification-issues)

## Creating the cluster

The default cluster configuration has the following specifications, which is only recommended for development purposes:

| Type                | Count | Memory  | Processors |
|:--------------------|------:|--------:|-----------:|
| Load Balancer (API) | 1     | 1024 MB | 1          |
| Master Node         | 3     | 4096 MB | 2          |
| Worker Node         | 2     | 4096 MB | 2          |

You can create a new cluster with this configuration by following these steps:

1. Create a new file called `kubernetes_cluster.tf` with the following contents:

    ```hcl
    module "kubernetes_cluster" {
      source = "github.com/danitso/terraform-module-clouddk-kubernetes-cluster"

      cluster_name   = "the-name-of-your-cluster-without-spaces-and-special-characters"
      provider_token = var.provider_token
    }

    variable "provider_token" {
      description = "The API key"
      type        = string
    }
    ```

1. Initialize your workspace

    ```bash
    docker run -v .:/workspace -it --rm danitso/terraform:0.12 init
    ```

    or using `cmd.exe`:

    ```batchfile
    docker run -v %CD%:/workspace -it --rm danitso/terraform:0.12 init
    ```

1. Create the cluster and provide an API key from [my.cloud.dk](https://my.cloud.dk/account/api-key) when prompted

    ```bash
    docker run -v .:/workspace -it --rm danitso/terraform:0.12 apply -auto-approve
    ```

    or using `cmd.exe`:

    ```batchfile
    docker run -v %CD%:/workspace -it --rm danitso/terraform:0.12 apply -auto-approve
    ```

You can modify the configuration by changing the [Input Variables](#input-variables) inside the `module` block.

_NOTE: The `danitso/terraform` image contains all the custom providers developed by [Danitso](https://danitso.com). In case you do not want to use this image, you must manually download and install the required provider plugins for Terraform listed under the [Requirements](#requirements) section._

## Accessing the cluster

If you have followed the steps in [Creating the cluster](#creating-the-cluster) without experiencing any problems, you should now be able to access the cluster with [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/):

```bash
export KUBECONFIG="$(pwd -P)/conf/the_name_of_your_cluster.conf"
kubectl get nodes
```

or using `cmd.exe`:

```batchfile
set KUBECONFIG=%CD%/conf/the_name_of_your_cluster.conf
kubectl get nodes
```

The `kubectl` command should output something similar to this:

```
NAME                                        STATUS    ROLES     AGE       VERSION
k8s-master-node-clouddk-cluster-1           Ready     master    2m        v1.15.2
k8s-master-node-clouddk-cluster-2           Ready     master    1m        v1.15.2
k8s-master-node-clouddk-cluster-3           Ready     master    1m        v1.15.2
k8s-worker-node-clouddk-cluster-default-1   Ready     <none>    1m        v1.15.2
k8s-worker-node-clouddk-cluster-default-2   Ready     <none>    1m        v1.15.2
```

The nodes may still be initializing in which case you will see the status _NotReady_. This should change to _Ready_ within a couple of minutes.

## Additional node pools

In case you need additional node pools with different hardware specifications or simply need to isolate certain services, you can go ahead and create a new one:

1. Append the following contents to the `kubernetes_cluster.tf` file:

    ```hcl
    module "kubernetes_node_pool_custom" {
      source = "github.com/danitso/terraform-module-clouddk-kubernetes-cluster/modules/nodes"

      api_addresses           = module.kubernetes_cluster.api_addresses
      api_ports               = module.kubernetes_cluster.api_ports
      bootstrap_token         = module.kubernetes_cluster.bootstrap_token
      certificate_key         = module.kubernetes_cluster.certificate_key
      cluster_name            = module.kubernetes_cluster.cluster_name
      control_plane_addresses = module.kubernetes_cluster.control_plane_addresses
      control_plane_ports     = module.kubernetes_cluster.control_plane_ports
      master                  = false
      node_count              = var.custom_node_count
      node_memory             = 4096
      node_pool_name          = "custom"
      node_processors         = 2
      provider_location       = module.kubernetes_cluster.provider_location
      provider_token          = module.kubernetes_cluster.provider_token
      unattended_upgrades     = true
    }

    variable "custom_node_count" {
      description = "The node count for the 'custom' node pool"
      default     = 2
      type        = number
    }
    ```

1. Re-initialize your workspace

    ```bash
    docker run -v .:/workspace -it --rm danitso/terraform:0.12 init
    ```

    or using `cmd.exe`:

    ```batchfile
    docker run -v %CD%:/workspace -it --rm danitso/terraform:0.12 init
    ```

1. Apply the changes

    ```bash
    docker run -v .:/workspace -it --rm danitso/terraform:0.12 apply -auto-approve
    ```

    or using `cmd.exe`:

    ```batchfile
    docker run -v %CD%:/workspace -it --rm danitso/terraform:0.12 apply -auto-approve
    ```

This will create a new node pool with the name `custom`, which can be targeted by using the label selector `kubernetes.cloud.dk/node-pool=custom`.

## Installed addons

The following addons are automatically installed by the module:

### [Cloud Controller Manager for Cloud.dk](https://github.com/danitso/clouddk-cloud-controller-manager)

Adds support for services of type `LoadBalancer` as well as other important features.

### [Weave Net](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/)

Adds a virtual network inside the cluster to allow containers to communicate across nodes.

## Variables

### Input

#### cluster_name

The name of the cluster.

**Default**: clouddk-cluster

#### load_balancer_count

The number of load balancers.

**Minimum**: 1

**Default**: 1

#### load_balancer_memory

The minimum amount of memory (in megabytes) for each load balancer.

**Minimum**: 512

**Default**: 1024

#### load_balancer_processors

The minimum number of processors (cores) for each load balancer.

**Minimum**: 1

**Default**: 1

#### master_node_count

The number of master nodes.

**Minimum**: 3

**Default**: 3

#### master_node_memory

The minimum amount of memory (in megabytes) for each master node.

**Minimum**: 2048

**Default**: 4096

#### master_node_processors

The minimum number of processors (cores) for each master node.

**Minimum**: 1

**Default**: 2

#### master_node_unattended_upgrades

Whether to enable unattended OS upgrades for the master nodes.

**Default**: true

#### network_storage_memory

The minimum amount of memory (in megabytes) for network storage servers.

**Default**: 4096

#### network_storage_processors

The minimum number of processors (cores) for network storage servers.

**Default**: 2

#### provider_location

The cluster's geographical location.

**Default**: dk1

#### provider_password

_This variable is currently unused._

#### provider_token

The API key.

#### provider_username

_This variable is currently unused._

#### worker_node_count

The number of worker nodes in the default worker node pool.

**Minimum**: 1

**Default**: 2

#### worker_node_memory

The minimum amount of memory (in megabytes) for each node in the default worker node pool.

**Minimum**: 2048

**Default**: 4096

#### worker_node_pool_name

The name of the default worker node pool.

**Default**: default

#### worker_node_processors

The minimum number of processors for each node in the default worker node pool.

**Minimum**: 1

**Default**: 2

#### worker_node_unattended_upgrades

Whether to enable unattended OS upgrades for the worker nodes.

**Default**: true

### Output

#### api_addresses

The IP addresses for the Kubernetes API.

#### api_ca_certificate

The CA certificate for the Kubernetes API.

#### api_endpoints

The endpoints for the Kubernetes API.

#### api_load_balancing_stats_password

The password for the Kubernetes API load balancing statistics page.

#### api_load_balancing_stats_urls

The Kubernetes API load balancing statistics URLs.

#### api_load_balancing_stats_username

The username for the Kubernetes API load balancing statistics page.

#### api_ports

The port numbers for the Kubernetes API.

#### bootstrap_token

The bootstrap token for the worker nodes.

#### certificate_key

The key for the certificate secret.

#### cluster_name

The name of the cluster.

#### config_file

The relative path to the configuration file for use with `kubectl`.

#### config_raw

The raw configuration for use with kubectl.

#### control_plane_addresses

The control plane addresses.

#### control_plane_ports

The control plane ports.

#### master_node_private_addresses

The private IP addresses of the master nodes.

#### master_node_public_addresses

The public IP addresses of the master nodes.

#### master_node_ssh_private_key

The private SSH key for the master nodes.

#### master_node_ssh_private_key_file

The relative path to the private SSH key for the master nodes.

#### master_node_ssh_public_key

The public SSH key for the master nodes.

#### master_node_ssh_public_key_file

The relative path to the public SSH key for the master nodes.

#### provider_location

The cluster's geographical location.

#### provider_token

The API key.

#### service_account_token

The token for the Cluster Admin service account.

#### worker_node_private_addresses

The private IP addresses of the worker nodes.

#### worker_node_public_addresses

The public IP addresses of the worker nodes.

#### worker_node_ssh_private_key

The private SSH key for the worker nodes.

#### worker_node_ssh_private_key_file

The relative path to the private SSH key for the worker nodes.

#### worker_node_ssh_public_key

The public SSH key for the worker nodes.

#### worker_node_ssh_public_key_file

The relative path to the public SSH key for the worker nodes.

## Frequently asked questions

### Why are the nodes occasionally rebooting after midnight?

Unattended OS upgrades are scheduled to run on the nodes on a daily basis. These upgrades may require a reboot in order to take effect in which case a reboot is scheduled for 00:00 UTC and onwards. The nodes in each pool will reboot 15 minutes apart, which results in a schedule similar to this:

* Node 1 reboots at 00:00 UTC
* Node 2 reboots at 00:15 UTC
* Node 3 reboots at 00:30 UTC
* Node 4 reboots at 00:45 UTC
* Node 5 reboots at 01:00 UTC

The delay between each reboot is meant to reduce the impact on a pool. However, in case the pool has only 2 nodes, you will still lose 50% of the capacity for the duration of the reboot (up to 5 minutes). That's why we recommend that you always provision at least 3 nodes per pool for production clusters.

You can also disable unattended OS upgrades by setting the two input variables [master_node_unattended_upgrades](#master_node_unattended_upgrades) and [worker_node_unattended_upgrades](#worker_node_unattended_upgrades) to `false`. However, this is not recommended unless you have another maintenance procedure in place.

**NOTE**: Unattended OS upgrades are permanently disabled for load balancers and needs to be maintained manually. This should reduce the risk of a cluster outage in case the cluster only has a single load balancer for the API.

## Known issues

### Additional load balancers triggers SSL verification issues

The first time the cluster is provisioned, the IP addresses of the load balancers and master nodes are included as alternative names in the SSL certificate. This certificate is only generated once, which results in verification issues when new load balancers are introduced afterwards.

The issue will be fixed in a future release of the module.
