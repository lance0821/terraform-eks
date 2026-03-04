# Velero starter (Backup/DR)

This starter adds Velero for Kubernetes object backups and PV snapshots to AWS.

## What this provides

- Helm release starter via `helm_releases.velero` in `infra/terraform.tfvars`.
- AWS values template in `values-aws-s3-ebs.yaml`.
- Daily schedule example in `schedule-daily.yaml`.
- Restore helper in `restore-latest-from-schedule.sh`.
- IAM policy template in `policies/velero-s3-ebs-snapshots-policy.json`.

## Enable Velero via Terraform

1. Set `helm_releases.velero.create = true` in `infra/terraform.tfvars`.
2. Set a real S3 bucket/region in `helm_releases.velero.values` (or use `values-aws-s3-ebs.yaml`).
3. Create a least-privilege IAM policy from `policies/velero-s3-ebs-snapshots-policy.json` and set its ARN in `helm_releases.velero.irsa_policy_arns`.
4. Apply:

```bash
mise run terraform:apply
```

## Render IAM policy template

```bash
VELERO_BUCKET="my-eks-velero-backups" envsubst < examples/velero/policies/velero-s3-ebs-snapshots-policy.json > /tmp/velero-policy.json
aws iam create-policy --policy-name VeleroS3EbsSnapshots --policy-document file:///tmp/velero-policy.json
```

## Verify backups

```bash
kubectl get backupstoragelocations -n velero
kubectl get volumesnapshotlocations -n velero
kubectl get backups -n velero
```

## Restore latest backup from schedule

```bash
./examples/velero/restore-latest-from-schedule.sh daily velero
```
