---
layout: post
title:  "Why network polciies in Kubernetes suck"
date:   2023-08-24 20:00:00 -0000
categories: [APIs,  Kubernetes, Networking]
---

Let's see whether these work on our cluster (Rancher Destop on macOS, v1.9.1)
```console

rtweed-tm02433-mbp:DVWA rtweed$ kubectl api-resources | grep network
ingressclasses                                 networking.k8s.io/v1                   false        IngressClass
ingresses                         ing          networking.k8s.io/v1                   true         Ingress
networkpolicies                   netpol       networking.k8s.io/v1                   true         NetworkPolicy
```

It exists, so surely it works?

```
kubectl create ns test-network-policies
# replace with URL?
kubectl --namespace test-network-policies apply -f src/static/2023-08-24-why-network-policies-suck/default-deny-egress.yaml
# let's run a pod and see what we can do
kubectl --namespace test-network-policies run -i -t --restart=Never test-egress-pod --image=busybox --command -- sh
If you don't see a command prompt, try pressing enter.
/ #
/ #
/ # nc -vz 1.1.1.1 53
1.1.1.1 (1.1.1.1:53) open
/ #
```
Wait, what?

```console
# Clean up
kubectl delete namespace test-network-policies
```

Let's check what cni we're running

```bash

kubectl -n kube-system get po --all-namespaces
NAMESPACE         NAME                                      READY   STATUS      RESTARTS       AGE
kube-system       helm-install-traefik-nps7t                0/1     Completed   0              181d
kube-system       helm-install-traefik-crd-rc6ft            0/1     Completed   0              181d
kube-system       traefik-56b8c5fb5c-tbxzf                  1/1     Running     24 (98m ago)   181d
kube-audit-rest   kube-audit-rest-5c6bc76b4c-7kd82          1/1     Running     29 (98m ago)   220d
kube-system       svclb-traefik-03c84d1c-vddj6              2/2     Running     46 (98m ago)   181d
kube-system       coredns-7c444649cb-qkh8c                  1/1     Running     15 (98m ago)   133d
kube-system       local-path-provisioner-79f67d76f8-wk97f   1/1     Running     56 (97m ago)   260d
kube-system       metrics-server-7b67f64457-s4gm6           1/1     Running     47 (97m ago)   181d
```
Hmm, nothing listed there. Let's check the machine filesystem

```bash
rdctl shell
sudo su # this is inside the Rancher Desktop VM
ls /etc/cni/net.d/
10-flannel.conflist      nerdctl-bridge.conflist
# Looks like flannel is installed
```

rdctl list-settings | jq .kubernetes.options
{
  "traefik": true,
  "flannel": true
}


Let's install calico cni
https://docs.tigera.io/calico/latest/getting-started/kubernetes/hardway/install-cni-plugin#install-the-plugin

```
rdctl shell
sudo su
mkdir -p /opt/cni/bin
curl -L -o /opt/cni/bin/calico https://github.com/projectcalico/cni-plugin/releases/download/v3.14.0/calico-arm64
curl -L -o /opt/cni/bin/calico-ipam https://github.com/projectcalico/cni-plugin/releases/download/v3.14.0/calico-ipam-arm64
mkdir -p /etc/cni/net.d/
cp /etc/rancher/k3s/k3s.yaml /etc/cni/net.d/calico-kubeconfig
chmod 600 /etc/cni/net.d/calico-kubeconfig
cat > /etc/cni/net.d/11-calico.conflist <<EOF
{
  "name": "k8s-pod-network",
  "cniVersion": "0.3.1",
  "plugins": [
    {
      "type": "calico",
      "log_level": "info",
      "datastore_type": "kubernetes",
      "mtu": 1400,
      "ipam": {
          "type": "calico-ipam"
      },
      "policy": {
          "type": "k8s"
      },
      "kubernetes": {
          "kubeconfig": "/etc/cni/net.d/calico-kubeconfig"
      }
    },
    {
      "type": "portmap",
      "snat": true,
      "capabilities": {"portMappings": true}
    }
  ]
}
EOF
```

Rather than doing this


kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml

kubectl --namespace test-network-policies run -i -t --restart=Never test-egress-pod --image=busybox --command -- sh
Events:
  Type     Reason                  Age                From               Message
  ----     ------                  ----               ----               -------
  Normal   Scheduled               86s                default-scheduler  Successfully assigned test-network-policies/test-egress-pod to lima-rancher-desktop
  Warning  FailedCreatePodSandBox  87s                kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "ece2c5fa55782dd2b5dacbef8beba66c22e248be3f48409434987dbe46b04cac": plugin type="calico" failed (add): failed to find plugin "calico" in path [/usr/libexec/cni]
  Normal   SandboxChanged          14s (x7 over 86s)  kubelet            Pod sandbox changed, it will be killed and re-created.

This isn't working because it assume that this has a proper kubelet, which k3s doesn't

In theory calico works, but it's a right pain to get working - especially with k8s

Try cilium instead?
https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#k8s-install-quick
