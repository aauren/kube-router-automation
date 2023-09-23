# Misc Kubernetes Info

This is just a generic place for additional information about Kubernetes that might be helpful.

## Easily Debug Containers

This allows you to attach to containers with networking tooling. Also ensure that the container's security context isn't
overriding what user the pod is executing as, or you may not be able to get `netadmin` which is required for most
networking changes or debugging tools like `tcpdump`.

```sh
kubectl debug -it whoami-txp6b --image=nicolaka/netshoot --target=whoami --share-processes=true --profile netadmin
```

## Create Load Balancer IPs

Setting up a LoadBalancer can be hard, however, it is possible to mock the LoadBalancer functionality, by changing the
status yourself. Obviously, this isn't a real LoadBalancer controller, but it can be helpful for testing. The trick is
that kubectl by itself won't allow you to modify the Status section on a Service without some careful handling. This is
how you can get around that:

```sh
$ kubectl -n default patch service whoami --subresource='status' --type='merge' -p '{"status":{"loadBalancer":{"ingress":[{"ip":"10.243.0.2"}]}}}'
```

The above will add a load balancer IP to a service object of type LoadBalancer so that you can experiment with
kube-router advertising it without having a controller running.
