region                    = "eu-central-1"
eks_cluster_name          = "devops-cluster"
environment               = "dev"
vpc_cidr_block            = "10.68.0.0/16"
availability_zones        = ["eu-central-1a", "eu-central-1b"]
public_subnet_cidr_blocks = ["10.68.1.0/24", "10.68.2.0/24"]
private_subnet_cidr_block = ["10.68.3.0/24", "10.68.4.0/24"]
eks-cw-logging            = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
worker-node-ssh-key       = "vanguard"
worker-node-max-size      = 3
worker-node-min-size      = 1
worker-node-desire-size   = 2
worker-node-instance-type = "t2.medium"
worker-node-disk-size     = 250

additional_tags = {
  ProvisionBy = "Terraform"
}