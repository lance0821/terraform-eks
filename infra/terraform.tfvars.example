project_name = "terraform-eks"
region       = "us-east-1"
environment  = "dev"
extra_tags = {
  Owner = "Platform Owner"
  Team  = "DevOps"
}

vpc_cidr           = "10.0.0.0/16"
az_count           = 3
kubernetes_version = "1.31"

enable_efs_filesystem = false
efs_encrypted         = true
efs_performance_mode  = "generalPurpose"
efs_throughput_mode   = "bursting"

enable_cluster_creator_admin_permissions = true

# Optional: grant additional IAM principals cluster access via EKS access entries.
# Set to {} if you do not want additional entries.
eks_access_entries = {
  # admin_role = {
  #   principal_arn = "arn:aws:iam::<ACCOUNT_ID>:role/PlatformAdmin"
  #   policy_associations = {
  #     admin = {
  #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #       access_scope = {
  #         type = "cluster"
  #       }
  #     }
  #   }
  # }

  # readonly_dev_ns = {
  #   principal_arn = "arn:aws:iam::<ACCOUNT_ID>:role/AppTeamReadOnly"
  #   policy_associations = {
  #     view_dev = {
  #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  #       access_scope = {
  #         type       = "namespace"
  #         namespaces = ["dev"]
  #       }
  #     }
  #   }
  # }

  # readonly_staging_ns = {
  #   principal_arn = "arn:aws:iam::<ACCOUNT_ID>:role/AppTeamReadOnly"
  #   policy_associations = {
  #     view_staging = {
  #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  #       access_scope = {
  #         type       = "namespace"
  #         namespaces = ["staging"]
  #       }
  #     }
  #   }
  # }
}

eks_managed_node_groups = {
  default = {
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 2
    desired_size   = 1
    capacity_type  = "ON_DEMAND"
  }

  spot = {
    instance_types = ["t3.medium", "t3a.medium", "m5.large", "m5a.large"]
    min_size       = 0
    max_size       = 6
    desired_size   = 2
    capacity_type  = "SPOT"

    labels = {
      workload_tier = "spot"
    }

    taints = {
      spot_only = {
        key    = "workload-tier"
        value  = "spot"
        effect = "NO_SCHEDULE"
      }
    }
  }
}

eks_addons = {
  coredns            = {}
  kube-proxy         = {}
  vpc-cni            = {}
  aws-ebs-csi-driver = {}
}

enable_aws_load_balancer_controller  = true
enable_metrics_server                = true
enable_external_dns                  = false
enable_cert_manager                  = true
enable_kube_prometheus_stack         = true
enable_karpenter                     = false
enable_argocd                        = true
enable_fluent_bit_cloudwatch_policy  = true
fluent_bit_cloudwatch_log_group_name = "/aws/eks/terraform-eks/cluster"

helm_releases = {
  external_secrets = {
    create           = false # set true to deploy
    chart            = "external-secrets"
    chart_version    = "0.18.2"
    repository       = "https://charts.external-secrets.io"
    namespace        = "external-secrets"
    create_namespace = true

    create_irsa_role          = true
    irsa_role_name_prefix     = "terraform-eks-external-secrets"
    irsa_service_account_name = "external-secrets"
    irsa_annotation_key       = "serviceAccount"

    # Attach least-privilege custom policies that allow ESO to read from
    # AWS Secrets Manager / SSM Parameter Store.
    irsa_policy_arns = {
      secrets_manager_read = "arn:aws:iam::<ACCOUNT_ID>:policy/ESOSecretsManagerRead"
      ssm_parameter_read   = "arn:aws:iam::<ACCOUNT_ID>:policy/ESOSsmParameterRead"
    }

    # Optional Helm values overrides.
    values = []
  }

  fluent_bit = {
    create           = false # set true to deploy
    chart            = "aws-for-fluent-bit"
    chart_version    = "0.1.35"
    repository       = "https://aws.github.io/eks-charts"
    namespace        = "amazon-cloudwatch"
    create_namespace = true

    create_irsa_role          = true
    irsa_role_name_prefix     = "terraform-eks-fluent-bit"
    irsa_service_account_name = "fluent-bit"
    irsa_annotation_key       = "serviceAccount"

    # CloudWatch IRSA policy is created/managed in Terraform and attached automatically.
    # For S3/OpenSearch, add additional destination-specific policy ARNs as needed.
    irsa_policy_arns = {}

    # CloudWatch Logs starter values. For S3/OpenSearch, replace with destination-specific values.
    values = [
      <<-EOT
      serviceAccount:
        create: true
        name: fluent-bit

      cloudWatch:
        enabled: true
        region: us-east-1
        logGroupName: /aws/eks/terraform-eks/cluster
        logStreamPrefix: fluent-bit-
      EOT
    ]
  }

  efs_csi = {
    create           = false # set true to deploy
    chart            = "aws-efs-csi-driver"
    chart_version    = "3.1.8"
    repository       = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
    namespace        = "kube-system"
    create_namespace = false

    create_irsa_role          = true
    irsa_role_name_prefix     = "terraform-eks-efs-csi"
    irsa_service_account_name = "efs-csi-controller-sa"
    irsa_annotation_key       = "controller.serviceAccount"

    # Attach AWS managed EFS CSI policy through module convenience flag.
    irsa_attach_efs_csi_policy = true

    values = []
  }

  velero = {
    create           = false # set true to deploy
    chart            = "velero"
    chart_version    = "9.2.0"
    repository       = "https://vmware-tanzu.github.io/helm-charts"
    namespace        = "velero"
    create_namespace = true

    create_irsa_role          = true
    irsa_role_name_prefix     = "terraform-eks-velero"
    irsa_service_account_name = "velero-server"
    irsa_annotation_key       = "serviceAccount.server"

    # Attach least-privilege custom policies for backup object storage and snapshots.
    irsa_policy_arns = {
      velero_backup_restore = "arn:aws:iam::<ACCOUNT_ID>:policy/VeleroS3EbsSnapshots"
    }

    # AWS S3 + EBS snapshot starter values (replace bucket/region).
    values = [
      <<-EOT
      serviceAccount:
        server:
          create: true
          name: velero-server

      credentials:
        useSecret: false

      initContainers:
        - name: velero-plugin-for-aws
          image: velero/velero-plugin-for-aws:v1.10.0
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - mountPath: /target
              name: plugins

      configuration:
        backupStorageLocation:
          - name: default
            provider: aws
            bucket: terraform-eks-velero-backups
            default: true
            config:
              region: us-east-1
        volumeSnapshotLocation:
          - name: default
            provider: aws
            config:
              region: us-east-1

      schedules:
        daily:
          schedule: "0 3 * * *"
          template:
            ttl: 168h
            includedNamespaces:
              - "*"
      EOT
    ]
  }
}
