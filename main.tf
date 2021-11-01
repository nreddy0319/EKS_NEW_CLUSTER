provider "aws" {
  region     = var.region
}

terraform {
  backend "s3" {}
}

resource "aws_eks_cluster" "main" {
  name                      = "${var.eks_cluster_name}-${var.environment}"
  role_arn                  = aws_iam_role.eks_cluster.arn
  enabled_cluster_log_types = var.eks-cw-logging
  tags                      = merge({ Name = "${var.eks_cluster_name}-${var.environment}-eks" }, tomap(var.additional_tags))

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id, aws_security_group.eks_nodes.id]
    endpoint_private_access = false
    endpoint_public_access  = true
    subnet_ids              = flatten([aws_subnet.private_subnet.*.id])
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_cluster_policy,
    aws_iam_role_policy_attachment.aws_eks_service_policy
  ]
}
resource "aws_iam_role" "eks_cluster" {
  name               = "${var.eks_cluster_name}-cluster-${var.environment}"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "aws_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "aws_eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}
resource "aws_security_group" "eks_cluster" {
  name        = "${var.eks_cluster_name}-security_group"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.custom_vpc.id
  tags        = merge({ Name = "${var.eks_cluster_name}-${var.environment}-security-group" }, tomap(var.additional_tags))
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "egress"
}
resource "aws_ecr_repository" "ecr" {
  name                 = "${var.eks_cluster_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"
  tags                 = merge({ Name = "${var.eks_cluster_name}-${var.environment}-ecr" }, tomap(var.additional_tags))

  image_scanning_configuration {
    scan_on_push = true
  }
}
