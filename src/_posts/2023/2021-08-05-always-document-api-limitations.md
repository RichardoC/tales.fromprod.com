---
layout: post
title:  "Using Kubernetes as a network scanner"
date:   2023-01-01 20:00:00 -0000
categories: [Kubernetes, APIs,  Nonsense]
---
# Using Kubernetes as a network scanner

While discussing legitimate uses for Admission webhooks (such as my side project [kube-audit-rest](https://github.com/RichardoC/kube-audit-rest)) I realised that these could be used to scan the networks surrounding the Kubernetes API server

## Surely the control plane can't make network calls?

Not quite, Admission webhooks can be arbitrary URLs served over HTTPS and I've discovered that all the control planes on AWS (EKS), Azure (AKS) and GCP (GKE) can all connect out to the internet, regardless of whether they are private or not. This means that the control planes can make outbound network calls to more than you expect (e.g. the can connect to more than just your worker nodes.) Misusing this for data exfiltration might be a different blog post if anyone's interested

## Which outbound calls can they make?

Admission webhooks can POST to HTTPs servers on any port, as long as the api server trusts the provided certificate, or you can provide a CA bundle.

### WARNING

This approach puts a lot of load on the API server, as it will attempt to connect to your "server" on every creation/mutation request. Make sure to only run ~ one at a time, and clean them up afterwards. You can entirely DOS a control plane if you create too many!

## How can this be used to probe a network?

Provided the server is hosting HTTPS, and has a CA bundle that you can find (or is already trusted) you now have a way to POST traffic to that server.

You can do this by creating a webhook that's triggered on the creation/mutation request of any resource (except the webhooks themselves) and checking if it worked

Example yaml to apply is below 

```yaml

---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration # Can also be a MutatingWebhookConfiguration if required
metadata:
  name: probing-${PORT}
  labels:
    app: probing
webhooks:
  - name: probing.svc.cluster.local
    failurePolicy: Ignore # Don't block requests if auditing fails
    timeoutSeconds: 1 # To prevent excessively slowing everything
    sideEffects: None
    clientConfig:
            url: "https://$SERVER:${PORT}" # or some other server/port combination
    rules: # To be reduced as needed
      - operations: [ "*" ]
        apiGroups: ["*"]
        apiVersions: ["*"]
        resources: ["*/*"] # This means a POST is attempted on any creation/mutation requests
        scope: "*"
    admissionReviewVersions: ["v1"]

```

You can detect that the server got your traffic (and is thus serving something) by running the following command

```console

kubectl get --raw /metrics | rest_client_requests_total | grep POST | grep $SERVER:${PORT}  grep -v 'code="<error>"'
rest_client_requests_total{code="409",host="$SERVER:${PORT}",method="POST"} 3

```

If the conditions aren't met, or the post is closed you will instead get

```console

kubectl get --raw /metrics | rest_client_requests_total | grep POST | grep $SERVER:${PORT}  grep -v 'code="<error>"'
rest_client_requests_total{code="<error>",host="$SERVER:${PORT}",method="POST"} 30

```

This can even be used to probe localhost on the APIServer host itself!

### What payload are we sending?

The API server will send an [AdmissionRequest](https://kubernetes.io/docs/reference/config-api/apiserver-admission.v1/#admission-k8s-io-v1-AdmissionRequest) request to the server we have configured in the `URL` above. We do not have control of this schema but we, as an attacker, have complete control of the kind, request etc etc because we can register API services, or custom resources to set these fields to whatever we want.

### Why does this work

Kubernetes provides metrics on all uses of its internal rest client, which is how it POSTs to the "admission controller" we created

## Which outbound calls are only in the cluster?

APIService's while cool, can only be sent to services within the cluster which rules out using them as a sneaky API proxy to anything surrounding the api server

### What about local API services?

(Un)fortunately Kubernetes assumes these will be served by the existing API server, so will not allow you to configure port numbers/etc

### What about forcing services to have external IPs?

You can force the IPs in an endpoint slice (the place k8s sends traffic to) to non standard IPs, but the specific metadata IPs are blocked since they're link local addresses.

I didn't investigate this further, as the API server doesn't directly connect to these, and instead sends the traffic via kubelets.

### What about ExternalName services?

Sadly not. While ExternalName services can point to anything you want (they function like CNAME DNS records) unfortunately the control plane will *not* proxy APIService API calls to them for you.

#### Example time

Create a DNS record pointing to the metadata service PI for the cloud vendor you're interested in
In this case azuremetadata.example.com points to 169.254.169.254 for Azure

```bash
kubectl create service externalname metadata --external-name azuremetadata.example.com --tcp 80:80
```

``` yaml
# Here's an api service that should send all relevant traffic to the metadata service
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1beta1.metadata
spec:
  group: metadata
  groupPriorityMinimum: 100
  insecureSkipTLSVerify: true
  service:
    name: metadata
    namespace: default
  version: v1beta1
  versionPriority: 100
```

```console

$ kubectl describe apiservice.apiregistration.k8s.io/v1beta1.metadata
E0331 23:24:32.582656     538 memcache.go:255] couldn't get resource list for metadata/v1beta1: the server is currently unable to handle the request
E0331 23:24:32.589760     538 memcache.go:106] couldn't get resource list for metadata/v1beta1: the server is currently unable to handle the request
E0331 23:24:32.597056     538 memcache.go:106] couldn't get resource list for metadata/v1beta1: the server is currently unable to handle the request
E0331 23:24:32.602439     538 memcache.go:106] couldn't get resource list for metadata/v1beta1: the server is currently unable to handle the request
Name:         v1beta1.metadata
Namespace:    
Labels:       <none>
Annotations:  <none>
API Version:  apiregistration.k8s.io/v1
Kind:         APIService
Spec:
  Group:                     metadata
  Group Priority Minimum:    100
  Insecure Skip TLS Verify:  true
  Service:
    Name:            metadata
    Namespace:       default
    Port:            443
  Version:           v1beta1
  Version Priority:  100
Status:
  Conditions:
    Last Transition Time:  2023-03-31T23:24:19Z
    Message:               unsupported service type "ExternalName"
    Reason:                FailedDiscoveryCheck
    Status:                False
    Type:                  Available
Events:                    <none>


```

Sadly k8s doesn't allow this

Also, if you attempt to portforward this service it will fail because the API server is trying to find a pod to send your traffic to, which doesn't exist. You will get a `failed precondition` error.


## TLDR

You can use legitimate functionality in Kubernetes to do (limited) scanning of the network (and localhost) of the API server.
Ensure you're watching your cluster/metrics for new Mutating/Validating webhooks!
