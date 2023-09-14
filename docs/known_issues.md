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

Some links I found on this issue:
* https://github.com/containerd/containerd/issues/4581
* https://github.com/containerd/containerd/issues/6704
* https://github.com/kubernetes/kubernetes/issues/97555

## Number of VMs / Instances

Right now the Ansible playbooks and Terraform variables aren't very well
constructed for dynamically adding more Kubernetes / BGP hosts. Probably a
significant number of changes would be necessary in order to make this work
properly. So at this point, users should consider the number of VMs / Instances
to be set at the repo defaults unless they really want to dive into it and
abstract the terraform / playbooks.

## kube-router / AWS Cloud Controller Manager race condition with IPv6

In order for nodes to get all of their IP addresses on their node object the
cloud provider has to do this. This was code that used to exist in the kubelet,
but it was removed in v1.25 and beyond. Now, this information comes from the
cloud-controller-manager. The problem is that the cloud-controller-manager isn't
able to route or do any networking until kube-router is available. Meanwhile, if
kube-router was enabled for IPv6 and it doesn't see an address for IPv6 on the
node, then it will refuse to start.

For whatever reason, this doesn't seem to happen all the time, but it definitely
does seem to happen from time to time. For more information, see:

* https://kubernetes.io/docs/tasks/administer-cluster/running-cloud-controller/#running-cloud-controller-manager

The easiest way around this is to temporarily disable IPv6, let the cloud
controller manager bootstrap and add the IPs, and then re-enable IPv6 in
kube-router.
