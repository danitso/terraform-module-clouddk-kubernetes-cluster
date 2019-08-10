# Kubernetes Cluster
Terraform Module for creating a Kubernetes Cluster on Cloud.dk

> **WARNING:** This project is under active development and should be considered alpha.

# Requirements
- [Terraform](https://www.terraform.io/downloads.html) 0.12+
- [Terraform Provider for Cloud.dk](https://github.com/danitso/terraform-provider-clouddk) 0.3+
- [Terraform Provider for SFTP](https://github.com/danitso/terraform-provider-sftp) 0.1+

# Getting started

The default cluster configuration has the following specifications, which is only recommended for development purposes:

| Node type           | Node count | Node processors | Node memory |
| --------------------|-----------:|----------------:|------------:|
| Load Balancer (API) | 1          | 1               | 1024 MB     |
| Master              | 3          | 2               | 4096 MB     |
| Worker              | 2          | 2               | 4096 MB     |

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

_NOTE: The `danitso/terraform` image contains all the custom providers developed by Danitso. In case you do not want to use this image, you must manually download and install the required provider plug-ins listed under the [Requirements](#requirements) section._

# Input Variables

## cluster_name
The name of the cluster.

_**NOTE:** The name will be truncated to 32 characters._

## load_balancer_count
The number of load balancers.

## load_balancer_memory
The minimum amount of memory (in megabytes) for each load balancer.

## load_balancer_processors
The minimum number of processors (cores) for each load balancer.

## master_node_count
The number of master nodes.

## master_node_memory
The minimum amount of memory (in megabytes) for each master node.

## master_node_processors
The minimum number of processors (cores) for each master node.

## provider_location
The cluster's geographical location.

## provider_password
_This variable is currently unused._

## provider_token
The API key.

## provider_username
_This variable is currently unused._

## worker_node_count
The number of worker nodes in the default worker node pool.

## worker_node_memory
The minimum amount of memory (in megabytes) for each node in the default worker node pool.

## worker_node_name
The name of the default worker node pool.

## worker_node_processors
The minimum number of processors for each node in the default worker node pool.

# Output Variables

## api_ca_certificate
The CA certificate for the Kubernetes API.

## api_endpoints
The endpoints for the Kubernetes API.

## config_file
The relative path to the configuration file for use with `kubectl`.

## config_raw
The raw configuration for use with kubectl.

## master_node_private_addresses
The private IP addresses of the master nodes.

## master_node_public_addresses
The public IP addresses of the master nodes.

## master_node_ssh_private_key
The private SSH key for the master nodes.

## master_node_ssh_private_key_file
The relative path to the private SSH key for the master nodes.

## master_node_ssh_public_key
The public SSH key for the master nodes.

## master_node_ssh_public_key_file
The relative path to the public SSH key for the master nodes.

## service_account_token
The token for the Cluster Admin service account.

## worker_node_private_addresses
The private IP addresses of the worker nodes.

## worker_node_public_addresses
The public IP addresses of the worker nodes.

## worker_node_ssh_private_key
The private SSH key for the worker nodes.

## worker_node_ssh_private_key_file
The relative path to the private SSH key for the worker nodes.

## worker_node_ssh_public_key
The public SSH key for the worker nodes.

## worker_node_ssh_public_key_file
The relative path to the public SSH key for the worker nodes.
