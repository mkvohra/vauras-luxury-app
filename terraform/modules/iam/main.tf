#GET CURRENT AWS ACCOUNT ID (used to build predictable ARNs below)

data "aws_caller_identity" "current" {}

#=========================================================================================================================================================================================
#SHARED TRUST POLICY 
#(scoped to a specific github environment name - eg: "dev" or "prod" -
#so a role can only be assumed by a workflow job actually running under
#that exact Github Environment, not just any branch/tag in the repo)

data "aws_iam_policy_document" "assume_role" {

  statement {

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [var.oidc_provider_arn]  
    }

    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = ["sts.amazonaws.com"]  
    }

    condition {
      test = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = ["repo:${var.github_org}/${var.github_repo}:environment:${var.environment}"]  
    }
  }  
}

#========================================================================================================================================================================
#1 TERRAFORM EXECUTION ROLE - used by infra.yml
#curated (not administratorAccess) but intentionally broad, since terraform 
#needs to create/modify most services this project touches

resource "aws_iam_role" "terraform" {

  name = "${var.project_name}-${var.environment}-terraform-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json    
}

data "aws_iam_policy_document" "terraform_permissions" {

  statement {
    sid = "NetworkingAndCompute"
    actions = [
      "ec2:*",
      "eks:*",
      "autoscaling:*",
      "elasticloadbalancing:*"  
    ]
    resources = ["*"]
  }

  statement {
    sid = "DataAndStorage"
    actions = [
      "rds:*",
      "s3:*",
      "secretsmanager:*"  
    ]
    resources = ["*"]
  }  

  statement {
    sid = "EdgeAndDNS"
    actions = [
      "cloudfront:*",
      "acm:*",
      "route53:*"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECRManage"
    actions = ["ecr:*"]
    resources = ["*"]
  }

  statement {
    #Terraform needs to create/attach IAM roles itself - eg the eks
    #cluster role, node role, and IRSA roles for cluster-autoscaler/ALB controller
    sid = "IAMForClusterRoles"
    actions = [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:TagRole",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:CreateOpenIDConnectProvider",
        "iam:GetOpenIDConnectProvider"
    ]
    resources = ["*"]
  }

  statement {
    #access to read/write the terraform state file itself, for this environment
    sid = "StateBackendAccess"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ] 
    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}",
      "arn:aws:s3:::${var.terraform_state_bucket}/*"
    ]
}

  statement {
    #access to acquire/release the state lock during apply 
    sid = "StateLockAccess"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]  
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.terraform_lock_table}"
    ]
  }
}

resource "aws_iam_policy" "terraform" {

  name = "${var.project_name}-${var.environment}-terraform-policy"

  policy = data.aws_iam_policy_document.terraform_permissions.json 
}

resource "aws_iam_role_policy_attachment" "terraform" {

  role = aws_iam_role.terraform.name

  policy_arn = aws_iam_policy.terraform.arn
}

#=================================================================================================================================================
#DEPLOYMENT ROLE - used by backend.yml
#Narrow: only push to THIS environment's ECR repos, describe THIS environment's 
#EKS cluster, and read THIS environment's one Secrets Manager secret 

resource "aws_iam_role" "deployment" {

  name = "${var.project_name}-${var.environment}-deployment-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "deployment_permissions" {

  statement {
    #this specific action does not support resource-level scoping in IAM
    sid = "ECRAuth"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "ECRPushPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage"
    ]
    resources = [
      for repo in var.ecr_repositories :
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}/${var.environment}/${repo}"
    ]
  }

  statement {
    sid = "EKSDescribeOnly"
    actions = ["eks:DescribeCluster"]
    resources = [
      "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
    ]
  }

  statement {
    #the "-*" suffix matters: AWS always appends its own random 6-character
    #suffix to a Secrets Manager ARN, even though we chose the readable name
    sid = "SecretsRead"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/app-secrets-*"
    ]
  }
}

resource "aws_iam_policy" "deployment" {

  name = "${var.project_name}-${var.environment}-deployment-policy"

  policy = data.aws_iam_policy_document.deployment_permissions.json
}

resource "aws_iam_role_policy_attachment" "deployment" {

  role = aws_iam_role.deployment.name

  policy_arn = aws_iam_policy.deployment.arn
}

#=================================================================================================================================================================
#FRONTEND ROLE - used by frontend.yml
#Narrow: Only sync THIS environment's frontend bucket, Invalidate Cloudfront.

resource "aws_iam_role" "frontend" {

  name = "${var.project_name}-${var.environment}-frontend-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "frontend_permissions" {

  statement {
    #the trailing "-*" covers the random suffix the s3 module appends
    #to keep the bucket name globally unique
    sid = "S3SyncAccess"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}-${var.environment}-frontend-*",
      "arn:aws:s3:::${var.bucket_name}-${var.environment}-frontend-*/*"
    ]
  }

  statement {
    # Cloudfront distribution IDs are AWS generated and unknowable before
    #creation, so this can't bescoped to one exact ARN - the mitigation
    #is restricting the action itself to invalidation only (no read/write/
    #delete on the distribution's configuration)
    sid = "CloudFrontInvalidateOnly"
    actions = ["cloudfront:CreateInvalidation"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "frontend" {

  name = "${var.project_name}-${var.environment}-frontend-policy"

  policy = data.aws_iam_policy_document.frontend_permissions.json
}

resource "aws_iam_role_policy_attachment" "frontend" {

  role = aws_iam_role.frontend.name

  policy_arn = aws_iam_policy.frontend.arn
}