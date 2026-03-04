# External Secrets starter manifests

These manifests provide a minimal end-to-end starter for syncing values from AWS Secrets Manager or AWS Systems Manager Parameter Store into Kubernetes Secrets.

## Files

Cluster-scoped (`ClusterSecretStore`):

- `clustersecretstore-aws-secretsmanager.yaml`: Cluster-wide provider config for AWS Secrets Manager.
- `externalsecret-example.yaml`: Example `ExternalSecret` that creates `Secret/app-secrets` in `default` namespace from AWS Secrets Manager.
- `clustersecretstore-aws-parameterstore.yaml`: Cluster-wide provider config for AWS Systems Manager Parameter Store.
- `externalsecret-ssm-example.yaml`: Example `ExternalSecret` that creates `Secret/app-params` in `default` namespace from SSM Parameter Store.

Namespace-scoped (`SecretStore`, tighter multi-tenant isolation):

- `secretstore-aws-secretsmanager.yaml`: Namespace-scoped store for AWS Secrets Manager (`default` namespace example).
- `externalsecret-secretsmanager-secretstore.yaml`: Example `ExternalSecret` that references `SecretStore/aws-secretsmanager`.
- `secretstore-aws-parameterstore.yaml`: Namespace-scoped store for AWS Systems Manager Parameter Store (`default` namespace example).
- `externalsecret-ssm-secretstore.yaml`: Example `ExternalSecret` that references `SecretStore/aws-parameterstore`.

Vault (`SecretStore`, namespace-scoped):

- `secretstore-vault.yaml`: Namespace-scoped Vault store (`default` namespace example).
- `externalsecret-vault-example.yaml`: Example `ExternalSecret` that references `SecretStore/vault`.

Vault (`ClusterSecretStore`, cluster-scoped shared platform):

- `clustersecretstore-vault.yaml`: Cluster-scoped Vault store managed by platform team.
- `externalsecret-vault-clusterstore-example.yaml`: Example `ExternalSecret` that references `ClusterSecretStore/vault`.

## Usage

1. Ensure External Secrets Operator is installed via Terraform (`helm_releases.external_secrets.create = true`).
2. Update placeholders in the files (`region`, remote secret key/path, and target namespace/name if needed).
3. Apply one of the following starter sets:

AWS Secrets Manager:

```bash
kubectl apply -f examples/external-secrets/clustersecretstore-aws-secretsmanager.yaml
kubectl apply -f examples/external-secrets/externalsecret-example.yaml
```

AWS Systems Manager Parameter Store:

```bash
kubectl apply -f examples/external-secrets/clustersecretstore-aws-parameterstore.yaml
kubectl apply -f examples/external-secrets/externalsecret-ssm-example.yaml
```

Namespace-scoped `SecretStore` (AWS Secrets Manager):

```bash
kubectl apply -f examples/external-secrets/secretstore-aws-secretsmanager.yaml
kubectl apply -f examples/external-secrets/externalsecret-secretsmanager-secretstore.yaml
```

Namespace-scoped `SecretStore` (AWS Systems Manager Parameter Store):

```bash
kubectl apply -f examples/external-secrets/secretstore-aws-parameterstore.yaml
kubectl apply -f examples/external-secrets/externalsecret-ssm-secretstore.yaml
```

HashiCorp Vault (`SecretStore`):

```bash
kubectl apply -f examples/external-secrets/secretstore-vault.yaml
kubectl apply -f examples/external-secrets/externalsecret-vault-example.yaml
```

HashiCorp Vault (`ClusterSecretStore`):

```bash
kubectl apply -f examples/external-secrets/clustersecretstore-vault.yaml
kubectl apply -f examples/external-secrets/externalsecret-vault-clusterstore-example.yaml
```

4. Verify synced Kubernetes Secret:

```bash
kubectl get secret app-secrets -n default
kubectl get externalsecret app-secrets -n default
```
