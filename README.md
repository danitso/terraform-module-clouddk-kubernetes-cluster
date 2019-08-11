# Kubernetes Cluster
Terraform Module for creating a Kubernetes Cluster on [Cloud.dk](https://cloud.dk)

> **WARNING:** This project is under active development and should be considered alpha.

## Requirements
- [Terraform](https://www.terraform.io/downloads.html) 0.12+
- [Terraform Provider for Cloud.dk](https://github.com/danitso/terraform-provider-clouddk) 0.3+
- [Terraform Provider for SFTP](https://github.com/danitso/terraform-provider-sftp) 0.1+

## Getting started

The default cluster configuration has the following specifications, which is only recommended for development purposes:

| Type                | Count | Memory  | Processors |
|:--------------------|------:|--------:|-----------:|
| Load Balancer (API) | 1     | 1024 MB | 1          |
| Master              | 3     | 4096 MB | 2          |
| Worker              | 2     | 4096 MB | 2          |

You can create a new cluster with this configuration by following these steps:

1. Create a new file called `kubernetes_cluster.tf` with the following contents:

    ```hcl
    module "kubernetes_cluster" {
        source = "github.com/danitso/terraform-module-clouddk-kubernetes-cluster"

        cluster_name   = "the-name-of-your-cluster-without-spaces-and-special-characters"
        provider_token = "the API key from https://my.cloud.dk/account/api-key"
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

1. Provision the resources

    ```bash
    docker run -v .:/workspace -it --rm danitso/terraform:0.12 apply -auto-approve
    ```

    or using `cmd.exe`:

    ```batchfile
    docker run -v %CD%:/workspace -it --rm danitso/terraform:0.12 apply -auto-approve
    ```

You can modify the configuration by changing the [Input Variables](#input-variables) on the `module` block.

_NOTE: The `danitso/terraform` image contains all the custom providers developed by [Danitso](https://danitso.com). In case you do not want to use this image, you must manually download and install the required provider plug-ins listed under the [Requirements](#requirements) section._

## Features

### Cloud Controller Manager

This module also provisions a [Cloud Controller Manager for Cloud.dk](https://github.com/danitso/clouddk-cloud-controller-manager). The controller adds support for services of type `LoadBalancer` as well as other important features.

## Input Variables

### cluster_name
The name of the cluster.

**Default**: danitso-kubernetes-cluster

### load_balancer_count
The number of load balancers.

**Default**: 1

### load_balancer_memory
The minimum amount of memory (in megabytes) for each load balancer.

**Default**: 1024

### load_balancer_processors
The minimum number of processors (cores) for each load balancer.

**Default**: 1

### master_node_count
The number of master nodes.

**Default**: 3

### master_node_memory
The minimum amount of memory (in megabytes) for each master node.

**Default**: 4096

### master_node_processors
The minimum number of processors (cores) for each master node.

**Default**: 2

### provider_location
The cluster's geographical location.

**Default**: dk1

### provider_password
_This variable is currently unused._

### provider_token
The API key.

### provider_username
_This variable is currently unused._

### worker_node_count
The number of worker nodes in the default worker node pool.

**Default**: 2

### worker_node_memory
The minimum amount of memory (in megabytes) for each node in the default worker node pool.

**Default**: 4096

### worker_node_pool_name
The name of the worker node pool.

**Default**: default

### worker_node_processors
The minimum number of processors for each node in the default worker node pool.

**Default**: 2

## Output Variables

### api_ca_certificate
The CA certificate for the Kubernetes API.

### api_endpoints
The endpoints for the Kubernetes API.

### api_load_balancing_stats_password
The password for the Kubernetes API load balancing statistics page.

### api_load_balancing_stats_urls
The Kubernetes API load balancing statistics URLs.

### api_load_balancing_stats_username
The username for the Kubernetes API load balancing statistics page.

### config_file
The relative path to the configuration file for use with `kubectl`.

### config_raw
The raw configuration for use with kubectl.

### master_node_private_addresses
The private IP addresses of the master nodes.

### master_node_public_addresses
The public IP addresses of the master nodes.

### master_node_ssh_private_key
The private SSH key for the master nodes.

### master_node_ssh_private_key_file
The relative path to the private SSH key for the master nodes.

### master_node_ssh_public_key
The public SSH key for the master nodes.

### master_node_ssh_public_key_file
The relative path to the public SSH key for the master nodes.

### service_account_token
The token for the Cluster Admin service account.

### worker_node_private_addresses
The private IP addresses of the worker nodes.

### worker_node_public_addresses
The public IP addresses of the worker nodes.

### worker_node_ssh_private_key
The private SSH key for the worker nodes.

### worker_node_ssh_private_key_file
The relative path to the private SSH key for the worker nodes.

### worker_node_ssh_public_key
The public SSH key for the worker nodes.

### worker_node_ssh_public_key_file
The relative path to the public SSH key for the worker nodes.
