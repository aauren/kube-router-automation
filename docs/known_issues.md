# Known Issues

This is a list of known issues with kube-router-automation

## FRR Subnets

FRR will only insert routes for kube-workers that are in the same subnet as the
host it is running on. It is possible, that this could be worked around with a
more complex FRR configuration. However, for now this is a limitation of the
tool.

See the following for more information on FRR:
* https://docs.frrouting.org/en/latest/zebra.html
* https://docs.frrouting.org/en/latest/bgp.html#configuring-frr-as-a-route-server

## cri-o kube-proxy Cleanup

cri-o has a much more limited interface than docker or containerd does. It
actually appears to be the upstream's intention that it should be subsidized by
podman for more advanced features. For now, I haven't worked out how to run the
kube-proxy cleanup container in cri-o, so the old iptables rules and stuff are
not currently cleaned up.

## containerd on Ubuntu 22.04

containerd appears to be broken when using Ubuntu 22.04's runc implementation.
Something about the way that pods share Linux namespaces causes the kubelet to
think that containers aren't running in the pod namespace even though they are.
This causes the kubelet to relentlessly kill off etcd and other core processes
which causes kube-apiserver and most of Kubernetes to fail.

For now, users should use Ubuntu 20.04 if they want to use containerd, otherwise
they should use cri-o or docker which both seem to work fine.

## Number of VMs / Instances

Right now the Ansible playbooks and Terraform variables aren't very well
constructed for dynamically adding more Kubernetes / BGP hosts. Probably a
significant number of changes would be necessary in order to make this work
properly. So at this point, users should consider the number of VMs / Instances
to be set at the repo defaults unless they really want to dive into it and
abstract the terraform / playbooks.
