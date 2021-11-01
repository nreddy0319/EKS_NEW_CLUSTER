
region                    = "eu-central-1"
eks_cluster_name          = "devops-cluster"
environment               = "prod"
vpc_cidr_block            = "10.78.0.0/16"
availability_zones        = ["eu-central-1a", "eu-central-1b"]
public_subnet_cidr_blocks = ["10.78.1.0/24", "10.78.2.0/24"]
private_subnet_cidr_block = ["10.78.3.0/24", "10.78.4.0/24"]
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
