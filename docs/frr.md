# Examples for Using FRR

A restriction of the current FRR config is that the FRR server must be in the
same subnet as the kube-router instances. This could likely be worked round by
adding routes to the servers, but for now, to keep it simple, this is something
that is required.

## Command-Line Examples

For all examples below, `vtysh` can be run interactively, the below shows how to
give non-interactive commands to `vtysh` via the `-c` flag.

### Seeing BGP Summary (shows basic peer state)

```sh
vtysh -c "show bgp summary"
```

### Seeing BGP Detail (includes RIB entries)

```sh
vtysh -c "show bgp detail"
```

### Seeing BGP Neighbor Detail

```sh
vtysh -c "show bgp neighbors <IP_of_neighbor>"
```

### See current configuration that FRR is using

```sh
vtysh -c "write terminal"
```

## Interactive Command Examples

This shows how to live-configure the router via vtysh when you use it
interactively.

```sh
# vtysh

Hello, this is FRRouting (version 8.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

host# list | include show bgp
    show bgp <ipv4|ipv6> vpn all [rd <ASN:NN_OR_IP-ADDRESS:NN|all>] [json]
    show bgp <ipv4|ipv6> vpn rd <ASN:NN_OR_IP-ADDRESS:NN|all> <A.B.C.D/M|X:X::X:X/M> [json]
    show bgp <ipv4|ipv6> vpn rd <ASN:NN_OR_IP-ADDRESS:NN|all> [json]
    show bgp [<ipv4|ipv6>] neighbors [<A.B.C.D|X:X::X:X|WORD>] graceful-restart [json]
    show bgp [<view|vrf> VIEWVRFNAME] martian next-hop
    ...
host# enable
host# config
host(config)# list | include ^\s+bgp
    bgp as-path access-list WORD [seq (0-4294967295)] <deny|permit> LINE...
    bgp community-list <(1-99)|standard WORD> [seq (0-4294967295)] <deny|permit> AA:NN...
    bgp community-list <(100-500)|expanded WORD> [seq (0-4294967295)] <deny|permit> AA:NN...
    bgp extcommunity-list <(1-99)|standard WORD> [seq (0-4294967295)] <deny|permit> AA:NN...
    bgp extcommunity-list <(100-500)|expanded WORD> [seq (0-4294967295)] <deny|permit> LINE...
    bgp graceful-shutdown
    bgp large-community-list (1-99) [seq (0-4294967295)] <deny|permit> AA:BB:CC...
    bgp large-community-list (100-500) [seq (0-4294967295)] <deny|permit> LINE...
    bgp large-community-list expanded WORD [seq (0-4294967295)] <deny|permit> LINE...
    bgp large-community-list standard WORD [seq (0-4294967295)] <deny|permit> AA:BB:CC...
    bgp no-rib
    bgp route-map delay-timer (0-600)
    bgp update-delay (0-3600) [(1-3600)]
host(config)# router bgp 4200000001
host(config-router)# neighbor kubepeers capability extended-nexthop
host(config-router)# exit
host(config)# exit
host# write terminal
Building configuration...

Current configuration:
!
...
```

## Configuration Examples

### Advertising a Network to kube-router Peers

Change /etc/frr/frr.conf as follows:

```diff
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
