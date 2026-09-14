#EKS CLUSTER IAM ROLE (used by eks control plane itself)

#EKS CLUSTER TRUST POLICY

data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = ["eks.amazonaws.com"]  
    }
  }  
}

#CREATING IAM ROLE (attaching trust policy too)

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-${var.environment}-eks-cluster-ROLE"

  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

#ATTACH EKS POLICY AND THE ROLE (attaching permission policy to the role )

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role = aws_iam_role.eks_cluster_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"  
}

#-----------------------------------------------------------------------------------------------------------------------

#CREATE EKS CLUSTER

resource "aws_eks_cluster" "this" {
  name = var.cluster_name

  version = var.cluster_version

  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = concat(
      var.private_subnet_ids,
      var.public_subnet_ids 
    )

    endpoint_private_access = true
    endpoint_public_access  = true

  }

  # ENABLE EKS ACCESS ENTRIES (the modern, AWS-recommended way to grant
  #IAM principals Kubernetes RBAC access)
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Project = var.project_name
    Environment = var.environment

    "k8s.io/cluster-autoscaler/enabled" = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  }

}

#----------------------------------------------------------------------------------------------------------
#NODE GROUP IAM ROLE

#TRUST POLICY

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = ["ec2.amazonaws.com"]  
    }
  }  
}

#CREATE NODE ROLE

resource "aws_iam_role" "node_role" {
  name = "${var.project_name}-${var.environment}-eks-node-role"

  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json  
}

#----------------------------------------------------------------------------------------

#ATTACH REQUIRED NODE POLICIES (separately)

#EKS WORKER POLICY

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role = aws_iam_role.node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"  
}

#ECR PULL POLICY

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role = aws_iam_role.node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"  
}

#CNI POLICY

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role = aws_iam_role.node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"  
}

#------------------------------------------------------------------------------------------------

#MANAGED NODE GROUP

resource "aws_eks_node_group" "this" {
  cluster_name = aws_eks_cluster.this.name

  node_group_name = "${var.environment}-node-group"

  node_role_arn = aws_iam_role.node_role.arn

  subnet_ids = var.private_subnet_ids

  instance_types = var.node_instance_types

  capacity_type = "ON_DEMAND"

  scaling_config {
    desired_size = var.desired_size

    min_size = var.min_size

    max_size = var.max_size
  }  

  update_config {
    max_unavailable = 1
  }

  depends_on = [

    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.ecr_readonly,
    aws_iam_role_policy_attachment.cni_policy
  ]

  tags = {
    Project = var.project_name
    Environment = var.environment
  }
}

#--------------------------------------------------------------------------

#OIDC PROVIDER FOR IRSA

#TLS CERTIFICATE
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

#CREATE EKS OIDC PROVIDER (Trusted Identity Provider Registry inside AWS)
# (after creating this oidc provider, aws trust tokens coming from this EKS OIDC issuer.)

resource "aws_iam_openid_connect_provider" "eks" {

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    data.tls_certificate.eks.certificates[0].sha1_fingerprint
  ]

  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}