project_name = "terraform-eks"
region       = "us-east-1"
environment  = "dev"
extra_tags = {
  Owner = "Lance Henderson"
  Team  = "DevOps"
}

vpc_cidr           = "10.0.0.0/16"
az_count           = 3
kubernetes_version = "1.31"

eks_managed_node_groups = {
  default = {
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 3
    desired_size   = 2
    capacity_type  = "ON_DEMAND"
  }
}

eks_addons = {
  coredns            = {}
  kube-proxy         = {}
  vpc-cni            = {}
  aws-ebs-csi-driver = {}
}