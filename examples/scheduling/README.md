# Scheduling examples (Spot vs On-Demand)

This folder contains minimal workload examples showing how to steer pods to Spot or On-Demand worker nodes.

## Files

- `deployment-spot-example.yaml`: Schedules pods to Spot nodes using:
  - `nodeSelector: workload_tier=spot`
  - toleration for `workload-tier=spot:NoSchedule`
- `deployment-ondemand-example.yaml`: Pins pods to On-Demand nodes using node affinity on `eks.amazonaws.com/capacityType=ON_DEMAND`.

## When to use each

Use Spot example for interruption-tolerant workloads:

- stateless APIs with multiple replicas
- async workers/consumers
- batch jobs and background processing

Use On-Demand example for higher stability requirements:

- stateful services without fast failover
- singleton/critical internal services
- operational tooling that should avoid interruption churn

## Apply examples

```bash
kubectl apply -f examples/scheduling/deployment-spot-example.yaml
kubectl apply -f examples/scheduling/deployment-ondemand-example.yaml
```

## Verify pod placement

```bash
kubectl get nodes --show-labels | grep -E 'workload_tier=spot|eks.amazonaws.com/capacityType'
kubectl get pods -n default -o wide
```

Single view (pod -> node -> capacity type):

```bash
kubectl get pods -n default -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}' | while read -r pod node; do cap=$(kubectl get node "$node" -o jsonpath='{.metadata.labels.eks\.amazonaws\.com/capacityType}'); echo "$pod $node $cap"; done
```

Check node details for capacity type and taints:

```bash
kubectl describe node <node-name>
```
