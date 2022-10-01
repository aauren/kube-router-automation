# Examples for Using FRR

A restriction of the current FRR config is that the FRR server must be in the
same subnet as the kube-router instances. This could likely be worked round by
adding routes to the servers, but for now, to keep it simple, this is something
that is required.

## Command-Line Examples

For all examples below, `vtysh` can be run interactively, the below shows how to
give non-interactive commands to `vtysh` via the `-c` flag.

**Seeing BGP Summary (shows basic peer state)**
```
$ vtysh -c "show bgp summary"
```

**Seeing BGP Detail (includes RIB entries)**
```
vtysh -c "show bgp detail"
```

## Configuration Examples

**Advertising a Network to kube-router Peers**

Change /etc/frr/frr.conf as follows:
```
# diff -u /etc/frr/frr.conf{,.mod}
--- /etc/frr/frr.conf   2022-03-18 20:28:44.863982897 +0000
+++ /etc/frr/frr.conf.mod       2022-03-18 20:28:33.559867871 +0000
@@ -52,7 +52,9 @@
 !
   # Filter imports & exports via route-map first
   neighbor kubepeers route-map IMPORTv4 in
-  neighbor kubepeers route-map UNACCEPTED out
+!
+  # Add an announcement for an address range
+  network 10.100.100.0/24
 !
   # "import" and "export" are different than the normal "in" and "out"
definitions that we normally see in policy
   # This is tied to route-server-client definition above
```

The above will advertise `10.100.100.0/24` to all of the kube peers. It also
removes the route-map that restricts outgoing BGP advertisements.
