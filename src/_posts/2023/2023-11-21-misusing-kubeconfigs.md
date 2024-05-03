---
layout: post
title:  "Misusing kubeconfigs"
date:   2023-11-01 11:00:00 -0000
categories: [JSON, logging,  ElasticSearch]
---
# Misusing kubeconfigs

When you use kubectl to do something on a cluster, it iterates through each file listed in the KUBECONFIG environment variable and it uses the first one that matches. This can be a problem if you have multiple contexts with the same name as it'll choose the first one it finds rather than the one you expected.

## auth-provider

These can be use to provision access tokens when required, https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins



minikube kubectl --ssh  --  get ns

minikube kubectl --ssh --  create ns example-admin
minikube kubectl --ssh --  --namespace example-admin create sa example-admin

minikube kubectl --ssh --  create clusterrolebinding example-admin-binding --clusterrole=cluster-admin  --serviceaccount=example-admin:example-admin

minikube kubectl --ssh --  --names pace example-admin create token example-admin --duration 10m


Turn this in to a blog post

---
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/rtweed/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Thu, 16 Nov 2023 17:17:01 GMT
        provider: minikube.sigs.k8s.io
        version: v1.30.1
      name: cluster_info
    server: https://192.168.39.120:8443
  name: minikube-manual
contexts:
- context:
    cluster: minikube-manual
    user: minikube-manual
  name: minikube-manual
current-context: minikube-manual
kind: Config
preferences: {}
users:
- name: minikube-manual
  user:
    auth-provider:
      config:
        cmd-args: kubectl --ssh --  --namespace example-admin create token example-admin
          --duration 10m -ojson
        cmd-path: minikube
        expiry-key: '{.status.expirationTimestamp}'
        token-key: '{.status.token}'
      name: gcp # magic to make this work
