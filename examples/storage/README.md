# Persistent storage starters (EBS + EFS)

This folder provides minimal Kubernetes manifests to validate dynamic PV provisioning with EBS and EFS on EKS.

## Prerequisites

- EBS CSI is enabled via `eks_addons.aws-ebs-csi-driver` in `infra/terraform.tfvars`.
- EFS CSI must be enabled via `helm_releases.efs_csi.create = true` in `infra/terraform.tfvars`.
- For EFS, either:
	- enable Terraform-managed EFS (`enable_efs_filesystem = true`), or
	- use an existing EFS filesystem + mount targets reachable from worker node subnets/security groups.

## Files

- `storageclass-ebs-gp3.yaml`: EBS gp3 `StorageClass`.
- `pvc-ebs-example.yaml`: Example `PersistentVolumeClaim` using EBS (`ReadWriteOnce`).
- `storageclass-efs.yaml`: EFS `StorageClass` template (dynamic access point mode) using `${EFS_FILE_SYSTEM_ID}`.
- `pvc-efs-example.yaml`: Example `PersistentVolumeClaim` using EFS (`ReadWriteMany`).

## Usage

Apply EBS storage example:

```bash
kubectl apply -f examples/storage/storageclass-ebs-gp3.yaml
kubectl apply -f examples/storage/pvc-ebs-example.yaml
```

Apply EFS storage example:

```bash
EFS_FILE_SYSTEM_ID="$(terraform -chdir=infra output -raw efs_file_system_id)" envsubst < examples/storage/storageclass-efs.yaml | kubectl apply -f -
kubectl apply -f examples/storage/pvc-efs-example.yaml
```

If you are using an existing EFS filesystem, replace the command substitution with your ID (for example `EFS_FILE_SYSTEM_ID=fs-1234567890abcdef0`).

Verify provisioning:

```bash
kubectl get storageclass
kubectl get pvc -n default
kubectl get pv
```
