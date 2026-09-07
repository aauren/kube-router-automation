# kube-router-terraform

Automation scripts (mostly centering around Terraform and Ansible) for setting up kube-router in a virtual environment.
For this we use the Terraform libvirt, or Terraform aws providers to spin up some VMs/instances and then use Ansible to
deploy Kubernetes and kube-router to those VMs/instances using kubeadm so that we can perform kube-router tests
end-to-end.

## Requirements for libvirt

* A Linux host that has the following resources available for VMs (this can be tweaked by setting different Terraform
  variables, but performance may suffer):
  * 6 cores
  * 9 GB of RAM
  * 60 GB of available Disk Space
* libvirt installed and working
* Your user is in the libvirt group so that you can perform libvirt actions in Terraform

Note: If you are using some OS's (like Ubuntu) that use AppArmor and you are placing your VM disks in an unconventional
location, you will need to follow the
[following instructions](https://github.com/dmacvicar/terraform-provider-libvirt/issues/920) in order to make it work
without an error:

Specifically, adding something like the following (that contains your VM image path) to:
`/etc/apparmor.d/local/abstractions/libvirt-qemu`

```sh
"/data/kvm/**/*qcow2" rwk,
```

## Requirements for AWS

For this you mostly just need an AWS account and to be willing to pay a small amount for the AWS services that
kube-router-automation uses.

Note, that you'll want to ensure that you run `terraform destroy` when you are finished with the resources so that you
don't continue to get charged.

## Setup

### General Setup

* [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* Install Python 3.12 or newer, then install the pinned Ansible Core release in a virtual environment

  ```bash
  python3 -m venv .venv
  source .venv/bin/activate
  python3 -m pip install -r ansible/requirements.txt
  ```

* Install Ansible collections

  ```bash
  ansible-galaxy collection install -r ansible/collections.yml
  ```

* For aws: Ensure that boto is installed for the AWS ansible collections to work correctly:

```sh
python3 -m pip install boto3
```

### AWS Specific Setup

* For aws: Ensure that the AWS Session Manager
  [plugin is installed](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
* By default this project uses AWS Session Manager (SSM) for managing AWS instances and providing a default inventory
  for Ansible to use. If you don't want to use AWS SSM and instead want to use a static inventory be sure to set the
  Terraform variable `enable_ssm` to `false`
* By default (`ansible_ssm_transport = "ssh"`) Ansible reaches the instances over SSH tunneled through Session
  Manager, using `aws ssm start-session --document-name AWS-StartSSHSession` as a `ProxyCommand`. No inbound security
  group rule or `aws_key_name` is needed for this, since Terraform generates an ed25519 key for `ssm-user` and writes
  the private half to `ansible/inventory/aws_ssm_ssh_key` (gitignored). This is quite a bit faster than the
  `aws_ssm` connection plugin because every task no longer has to bounce its payload through S3, and we get SSH
  ControlPersist and pipelining for free
* If you'd rather use the `amazon.aws.aws_ssm` connection plugin, set `ansible_ssm_transport = "plugin"`. In that
  mode the generated inventory connects with `aws_ssm_retry`, a small wrapper around `amazon.aws.aws_ssm` that lives
  in `ansible/playbooks/connection_plugins/`. It exists because upstream ignores `ansible_aws_ssm_retries`, and
  without working retries any SSM agent restart mid-play (such as the `AWS-UpdateSSMAgent` association) fails the
  host. The `ansible.cfg` in the repo root points ad-hoc `ansible` runs at it, so be sure to run from the repo root

### Libvirt Specific Setup

* For libvirt: Ensure that `wget` and `qemu-img` commands are installed and available on the host running terraform
* For libvirt: Add the following to your `/etc/hosts` file so that the hosts are easier to reference:

```sh
10.241.0.10 bgp-route-vm1
10.241.0.20 kube-router-vm1
10.241.0.21 kube-router-vm2
```

* For libvirt: Add the following to your `~/.ssh/config` file so that these hosts changing doesn't cause issues with
  SSH:

```sh
Host kube-router-vm*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
Host bgp-route-vm*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

## Create the Terraform VMs / Instances

* Change directory into either `terraform_libvirt` or `terraform_aws`
* Customize any variables that you want to run differently from the default and place them in the vars file provided for
  you and helpfully excluded from git. See variables section below.
* From this project repo run: `terraform init`
* From this project repo run (make sure to substitute your variables for the path below):
  `terraform apply -auto-approve -var-file="../vars/<my_vars.tfvars>"`

## Setup the Kubernetes Cluster on the VMs / Instances

Note that for either of these you can choose to run containerd with the playbook `kube-router-containerd.yaml` or cri-o
with the playbook `kube-router-crio.yaml` the big difference between the following is which inventory file you use.

### Libvirt Specific Instructions

The libvirt one is static and is distributed with the repo and connects using your `/etc/hosts` & `~/.ssh/config` that
you made above.

* For libvirt: From this project repo run:

```sh
ansible-playbook -i ansible/inventory/hosts.yaml ansible/playbooks/kube-router-containerd.yaml`
```

### AWS Specific Instructions

By default the AWS inventory is dynamic and is generated by Ansible as part of the Terraform run
above.

* For SSM enabled AWS: From this project repo run:

```sh
ansible-playbook -i ansible/inventory/aws_ec2.yaml ansible/playbooks/kube-router-crio.yaml
```

* For static inventory enabled AWS (`enable_ssm: false`): From this project repo run:

```sh
ansible-playbook -i ansible/inventory/aws.yaml ansible/playbooks/kube-router-crio.yaml
```

## Tearing Down Your Cluster

Once you are all done with your work on kube-router, you can tear down the VMs by running:

* From this project repo run: `terraform destroy -auto-approve`

## Configuration

### Terraform libvirt Variables

* **image_cache_dir** - `/tmp/kube-router-img-cache` - In order to ensure Terraform runs are optimized, the execution
  will download images once on the first run and then continue to use them for all subsequent runs. This defines
  the directory that it will cache them in.
* **ubuntu_image_url** -
  `https://cloud-images.ubuntu.com/releases/26.04/release/ubuntu-26.04-server-cloudimg-amd64.img` - This is the image
  that you wish to use as your base Ubuntu image for running kube-router on.
* **disk_size** - `20G` - This is the size that your OS image will be expanded to for your root disk. Accepts any valid
  `qemu-img` size.
* **vm_pool_dir** - `/var/lib/libvirt/kube-router-images` - Where to store base images for kube-router VMs created by
  Terraform
* **root_password** - `kube-router-linux` - The password to set for the root user of the created VMs. This should be
  in the form of a salted password generated using something like the following command:
  `mkpasswd -m SHA-512 --rounds=4096 <password_here>`
* **username** - `kube-router` - The username for the account that will be enabled for SSH
* **user_ssh_key** - NO_DEFAULT_SET - The SSH key that you want to use if you intend to SSH to this VM. By default,
  password authentication is not enabled on the hosts, so setting this is effectively the only way to SSH to this host.
* **user_groups** - `adm` - Additional groups to add the user (identified by `username` above) to
* **cpu_count** - `2` - Numerical number for how many VCPUs to expose to each Kubernetes host VM
* **memory_size** - `3072` - Number in Megabytes for how much memory to expose to each Kubernetes host VM
* **bgp_cpu_count** - `1` - Numerical number for how many VCPUs to expose to each BGP route server VM
* **bgp_memory_size** - `512` - Number in Megabytes for how much memory to expose to each BGP route server VM

### Terraform AWS Variables

* **aws_key_name** - NO_DEFAULT_SET - The SSH key name in AWS that you want to use for logging into the instances
* **enable_ssm** - `true` - If true, the Ansible inventory file will be generated to connect to AWS instances using SSM.
  If false, then SSH will be used with a static Ansible inventory.
* **region** - `us-west-2` - The AWS region that you are deploying into
* **name** - `kube-router` - The default name to use for AWS tags and instances
* **tags** - `owner = "kube-router"` - Any additional tags that you want to set on your AWS resources
* **cidr_block** - `10.0.0.0/18` - The default CIDR block to use for all of the VPCs that we create
* **pod_net** - `10.242.0.0/16` - The default pod network to use for Kubenretes
* **public_cidr_breakdowns** - (see variables) - The CIDR blocks that you want to use for your instances that are
  available publicly
* **private_cidr_breakdowns** - (see variables) - The CIDR blocks that you want to use for your instances that are
  available privately
* **kube_worker_instance_size** - `t3.medium` - The instance size that you want to use for your kube-workers
* **bgp_receiver_instance_size** - `t3.micro` - The instance size that you want to use for your bgp-workers
* **kube_worker_disk_size** - `50` - The disk size that you want to use for your kube-workers
* **bgp_receiver_disk_size** - `10` - The disk size that you want to use for your bgp-workers
* **ami_filter** -
  `ubuntu-minimal/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-minimal-*` - Allows you to set a filter for the AMI that
  you want to base your instances off of
* **ami_owners** - `amazon` - List of AMI owners to help direct searching for available AMIs
* **ami_default_user** - `ubuntu` - The default user of the AMI which is used when generating static AWS manifests
  (not used in SSM mode)
* **ami_type** - `ubuntu` - The default type of the OS for the selected AMI type (used for detecting the proper package
  names in cloud-init installs)
* **ansible_ssm_transport** - `ssh` - How Ansible connects when `enable_ssm` is true. `ssh` tunnels SSH through
  Session Manager (fast, no bucket needed), `plugin` uses the `amazon.aws.aws_ssm` connection plugin
* **ansible_ssm_bucket_name** - `kube-router-aws-ssm-ansible` - Default bucket name to use for discovering SSM
  information in Ansible (only used when `ansible_ssm_transport` is `plugin`)

### Ansible Variables

See comments in Playbooks
