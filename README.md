# kube-router-terraform

Automation scripts (mostly centering around Terraform and Ansible) for setting
up kube-router in a virtual environment. For this we use the Terraform libvirt,
or Terraform aws providers to spin up some VMs/instances and then use Ansible to
deploy Kubernetes and kube-router to those VMs/instances using kubeadm so that
we can perform kube-router tests end-to-end.

## Requirements for libvirt

* A Linux host that has the following resources available for VMs (this can be
tweaked by setting different Terraform variables, but performance may suffer):
  * 6 cores
  * 9 GB of RAM
  * 60 GB of available Disk Space
* libvirt installed and working
* Your user is in the libvirt group so that you can perform libvirt actions in
  Terraform

Note: If you are using some OS's (like Ubuntu) that use AppArmor and you are
placing your VM disks in an unconventional location, you will need to follow
the [following instructions](https://github.com/dmacvicar/terraform-provider-libvirt/issues/920)
in order to make it work without an error:

Specifically, adding something like the following (that contains your VM
image path) to: `/etc/apparmor.d/local/abstractions/libvirt-qemu`

```sh
"/data/kvm/**/*qcow2" rwk,
```

## Requirements for AWS

For this you mostly just need an AWS account and to be willing to pay a small
amount for the AWS services that kube-router-automation uses.

Note, that you'll want to ensure that you run `terraform destroy` when you are
finished with the resources so that you don't continue to get charged.

## Setup

* [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* For libvirt: Ensure that `wget` and `qemu-img` commands are installed and
  available on the host running terraform
* For libvirt: Add the following to your `/etc/hosts` file so that the hosts are
  easier to reference:

```sh
10.241.0.10 bgp-route-vm1
10.241.0.20 kube-router-vm1
10.241.0.21 kube-router-vm2
```

* For libvirt: Add the following to your `~/.ssh/config` file so that these
  hosts changing doesn't cause issues with SSH:

```sh
Host kube-router-vm*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
Host bgp-route-vm*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

* Change directory into either `terraform_libvirt` or `terraform_aws`
* Customize any variables that you want to run differently from the default and
  place them in the vars file provided for you and helpfully excluded from git.
  See variables section below.
* From this project repo run: `terraform init`
* From this project repo run:
  `terraform apply -auto-approve -var-file="../vars/my_vars.tfvars"`
* From this project repo run:
  `ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/kube-router-containerd.yaml`

Once you are all done with your work on kube-router, you can tear down the VMs
by running:

* From this project repo run: `terraform destroy -auto-approve`

## Terraform libvirt Variables

* **image_cache_dir** - `/tmp/kube-router-img-cache` - In order to ensure
  Terraform runs are optimized, the execution will download images once on the
  first run and then continue to use them for all subsequent runs. This defines
  the directory that it will cache them in.
* **ubuntu_image_url** -
`https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img` -
This is the image that you wish to use as your base Ubuntu image for running kube-router on.
* **disk_size** - `20G` - This is the size that your OS image will be expanded
  to for your root disk. Accepts any valid `qemu-img` size.
* **vm_pool_dir** - `/var/lib/libvirt/kube-router-images` - Where to store base
  images for kube-router VMs created by Terraform
* **root_password** - `kube-router-linux` - The password to set for the root
  user of the created VMs. This should absolutely be changed, especially if
  exposing to another network.
* **username** - `kube-router` - The username for the account that will be
  enabled for SSH
* **user_ssh_key** - NO_DEFAULT_SET - The SSH key that you want to use if you
  intend to SSH to this VM. By default, password authentication is not enabled
  on the hosts, so setting this is effectively the only way to SSH to this host.
* **user_groups** - `adm` - Additional groups to add the user (identified by
  `username` above) to
* **cpu_count** - `2` - Numerical number for how many VCPUs to expose to each
  Kubernetes host VM
* **memory_size** - `3072` - Number in Megabytes for how much memory to expose
  to each Kubernetes host VM
* **bgp_cpu_count** - `1` - Numerical number for how many VCPUs to expose to
  each BGP route server VM
* **bgp_memory_size** - `1024` - Number in Megabytes for how much memory to
  expose to each BGP route server VM

## Terraform aws Variables

* **aws_key_name** - NO_DEFAULT_SET - The SSH key name in AWS that you want to
  use for logging into the instances
* **region** - `us-west-2` - The AWS region that you are deploying into
* **name** - `kube-router` - The default name to use for AWS tags and instances
* **tags** - `owner = "kube-router"` - Any additional tags that you want to set
  on your AWS resources
* **cidr_block** - `10.0.0.0/18` - The default CIDR block to use for all of the
  VPCs that we create
* **public_cidr_breakdowns** - (see variables) - The CIDR blocks that you want
  to use for your instances that are available publicly
* **private_cidr_breakdowns** - (see variables) - The CIDR blocks that you want
  to use for your instances that are available privately
* **kube_worker_instance_size** - `t3.medium` - The instance size that you want
  to use for your kube-workers
* **bgp_receiver_instance_size** - `t3.micro` - The instance size that you want
  to use for your bgp-workers
* **kube_worker_disk_size** - `50` - The disk size that you want to use for your
  kube-workers
* **bgp_receiver_disk_size** - `10` - The disk size that you want to use for
  your bgp-workers
* **ami_filter** -
  `ubuntu-minimal/images/hvm-ssd/ubuntu-jammy-*-amd64-minimal-*` -
  Allows you to set a filter for the AMI that you want to base your instances
  off of


## Ansible Variables

See comments in Playbooks
