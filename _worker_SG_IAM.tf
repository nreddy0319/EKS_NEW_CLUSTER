resource "aws_security_group" "eks_nodes" {
    name        = "${var.eks_cluster_name}-${var.environment}-node-security-group"
    description = "Security group for all nodes in the cluster"
    vpc_id      = aws_vpc.custom_vpc.id
  
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      Name = "${var.eks_cluster_name}-${var.environment}-node-security-group"
      "kubernetes.io/cluster/${var.eks_cluster_name}-${var.environment}" = "owned"
    }
  }
  
  resource "aws_security_group_rule" "nodes" {
    description              = "Allow nodes to communicate with each other"
    from_port                = 0
    protocol                 = "-1"
    security_group_id        = aws_security_group.eks_nodes.id
    source_security_group_id = aws_security_group.eks_nodes.id
    to_port                  = 65535
    type                     = "ingress"
  }
  
  resource "aws_security_group_rule" "nodes_inbound" {
    description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
    from_port                = 1025
    protocol                 = "tcp"
    security_group_id        = aws_security_group.eks_nodes.id
    source_security_group_id = aws_security_group.eks_cluster.id
    to_port                  = 65535
    type                     = "ingress"
  }

resource "aws_iam_role" "eks_nodes" {
  name                 = "${var.eks_cluster_name}-worker-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_workers.json
}

data "aws_iam_policy_document" "assume_workers" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "aws_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "aws_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ec2_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
  role = aws_iam_role.eks_nodes.name
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "${var.eks_cluster_name}-ClusterAutoScaler"
  description = "Give the worker node running the Cluster Autoscaler access to required resources and actions"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": "*"
        }
    ]
})
}
# Nodes in private subnets
resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.eks_cluster_name}-${var.environment}-private-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = flatten([aws_subnet.private_subnet.*.id])
  ami_type        = "AL2_x86_64"
  disk_size       = var.worker-node-disk-size
  instance_types  = [var.worker-node-instance-type]
  tags            = merge({ Name = "${var.eks_cluster_name}-${var.environment}-private-node-group" }, tomap(var.additional_tags))

  remote_access {
    ec2_ssh_key = var.worker-node-ssh-key
  }

  scaling_config {
    desired_size = var.worker-node-desire-size
    max_size     = var.worker-node-max-size
    min_size     = var.worker-node-min-size
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_eks_worker_node_policy,
    aws_iam_role_policy_attachment.aws_eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_read_only,
  ]
}
