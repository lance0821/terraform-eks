# Architecture

# Architecture

## Module dependency diagram
```mermaid
graph TD
    subgraph "infra/ — root orchestration"
        PROVIDERS["providers.tf<br/><i>reads module outputs from state</i>"]
        IAM["iam.tf<br/><i>EBS CSI IRSA · Fluent Bit policy</i>"]
        MAIN["main.tf<br/><i>wires all modules</i>"]
        GATE["null_resource<br/><b>node readiness gate</b>"]
    end

    subgraph "modules/"
        VPC["modules/vpc<br/><i>wraps vpc 6.6</i>"]
        EKS["modules/eks<br/><i>wraps eks 21.15</i>"]
        EFS["modules/efs<br/><i>SG · FS · mounts · backup</i>"]
        ADDONS["modules/eks-addons<br/><i>7 opinionated + generic</i>"]
        HELM["modules/helm-release<br/><i>helm_release + optional IRSA</i>"]
    end

    MAIN --> VPC
    MAIN --> EKS
    MAIN --> EFS
    MAIN --> GATE
    GATE -->|"waits for ACTIVE nodes"| ADDONS
    VPC -->|"vpc_id · subnets"| EKS
    VPC -->|"vpc_id · subnets · cidr"| EFS
    EKS -->|"cluster_name · endpoint · oidc_arn · node_sg_id"| ADDONS
    EKS -->|"node_security_group_id"| EFS
    EKS -->|"oidc_provider_arn"| IAM
    IAM -->|"ebs_csi_irsa_arn"| EKS
    ADDONS -->|"for each addon"| HELM
    PROVIDERS -.->|"cluster_endpoint · CA from state"| EKS

    style GATE fill:#f9a825,stroke:#f57f17,color:#000
    style PROVIDERS fill:#e3f2fd,stroke:#1565c0
    style IAM fill:#e8f5e9,stroke:#2e7d32
```

## Data flow
```mermaid
sequenceDiagram
    participant TF as Terraform
    participant VPC as modules/vpc
    participant EKS as modules/eks
    participant IAM as infra/iam.tf
    participant EFS as modules/efs
    participant GATE as null_resource
    participant ADDONS as modules/eks-addons

    TF->>VPC: create network
    VPC-->>TF: vpc_id, subnets

    TF->>EKS: create cluster + node groups
    EKS-->>TF: endpoint, oidc_arn, node_sg_id

    TF->>IAM: create EBS CSI IRSA role
    IAM-->>EKS: service_account_role_arn (via locals)

    TF->>EFS: create filesystem (optional)
    EFS-->>TF: file_system_id

    TF->>GATE: wait for nodes ACTIVE + Ready
    GATE-->>TF: ready

    TF->>ADDONS: deploy Helm charts
    ADDONS-->>TF: release statuses
```

## IRSA auto-injection flow
```mermaid
flowchart LR
    A["caller passes<br/>create_irsa_role = true"] --> B["helm-release module<br/>creates IAM role via<br/>iam-role-for-service-accounts"]
    B --> C["builds irsa_set:<br/>SA create = true<br/>SA name<br/>SA annotation = role ARN"]
    C --> D["concat with<br/>caller's set values"]
    D --> E["helm_release resource<br/>set = merged_set<br/><i>last-wins merge</i>"]
```

## Layer responsibilities

| Layer | Responsibility | Dependencies |
|-------|---------------|-------------|
| `modules/vpc` | Network: VPC, subnets, NAT, IGW | None |
| `modules/eks` | Control plane: cluster, node groups, addons, IRSA OIDC | None |
| `modules/efs` | Storage: EFS filesystem, SG, mount targets, backup, lifecycle | None |
| `modules/helm-release` | Primitive: single Helm chart + optional IRSA role | None |
| `modules/eks-addons` | Composition: 7 opinionated addons + generic passthrough | `helm-release` |
| `infra/` | Orchestration: wires modules, cross-cutting IAM, readiness gate | All modules |

## Why we use wrapper modules

Every module in `modules/` wraps an upstream `terraform-aws-modules/*` community
module (or raw AWS resources for EFS). The wrappers exist for three reasons:

1. **Validate-time guardrails.** Wrappers add `variable` validation blocks that
   catch misconfigurations at `terraform validate` — before plan or apply. The
   community modules accept almost anything and fail with cryptic AWS API errors
   at apply time. Examples: NAT gateway mutual exclusion check, subnet/AZ count
   match, CIDR format validation, public endpoint CIDR blocklist.

2. **Opinionated defaults.** Wrappers encode production-safe defaults (encryption
   on, public endpoint off, all log types enabled, KMS key created) so teams
   can't accidentally deploy insecure clusters. The upstream modules default to
   permissive settings.

3. **Consistent interface.** All wrappers follow the same pattern — flat variable
   inputs, direct outputs, `versions.tf` with provider constraints. New team
   members learn one pattern and apply it everywhere.

**Rule of thumb:** We wrap when we add validation, defaults, or interface
simplification. If a wrapper would be pure passthrough with zero added logic,
call the upstream module directly from `infra/`.
