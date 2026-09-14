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

#=================================================================================================================================================================================
# PLAN ONLY TRUST POLICY
#(scoped to the repo generally - any ref/branch/tag/PR - deliberately NOT 
#scoped to a Github environment claim like the shared trust policy above.
#Plan is read-only; requiring a prrotected environment for it would force
#every plan to wait on the same required-reviewers approval that's meant
#to gate apply only)

data "aws_iam_policy_document" "assume_role_plan" {

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
      values = [
        "repo:${var.github_org}/${var.github_repo}:pull_request",
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/*",
        "repo:${var.github_org}/${var.github_repo}:ref:refs/tags/*"
      ]
    }
  }
}

#========================================================================================================================================================================
# TERRAFORM PLAN-ONLY ROLE - used by infra.yml's plan-level-* jobs
# Read-only mirror of the terraform role above: Describe/Get/List actions only,
#across every service any module in this project actually manages.
# No Create/Update/Delete/Attach/PassRole anywhere in this policy.

resource "aws_iam_role" "terraform_plan" {
  
  name = "${var.project_name}-${var.environment}-terraform-plan-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_plan.json
}

data "aws_iam_policy_document" "terraform_plan_permissions" {

  statement {
    #read-only mirror of NetworkingAndCompute (vpc module: aws_vpc/
    #aws_subnet/aws_internet_gateway/aws_nat_gateway/aws_eip/route tables;
    #eks module: aws_eks_cluster/aws_eks_node_group)
    sid = "NetworkingAndComputeReadOnly"
    actions = [
      "ec2:Describe*",
      "eks:Describe*",
      "eks:List*",
      "autoscaling:Describe*",
      "elasticloadbalancing:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    #read-only mirror of DataAndStorage (rds module; s3 module's frontend
    #bucket - resources = "*" here for the same reason the original
    #terraform role uses "*": the s3 module appends a random suffix to
    #the bucket name, so the exact ARN isn't knowable statically;
    #secretsmanager module's secret metadata, not its value - see the
    #separate SecretsValueReadOnly statement below for that)
    sid = "DataAndStorageReadOnly"
    actions = [
      "rds:Describe*",
      "rds:ListTagsForResource",
      "s3:GetBucket*",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = ["*"]
  }

  statement {
    #the secrets-manager module manages aws_secretsmanager_secret_version
    #directly, and refreshing that resource during plan needs the actual
    #value (not just metadata) to detect drift - scoped to just this
    #project/environment's secret, same ARN pattern the deployment role
    #already uses, not account-wide
    sid = "SecretsValueReadOnly"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/app-secrets-*"
    ]
  }

  statement {
    #read-only mirror of EdgeAndDNS (acm module's certificate + validation
    #records; cloudfront module's distribution; dns_record module's
    #record; addons module's data "aws_route53_zone" lookup)
    sid = "EdgeAndDNSReadOnly"
    actions = [
      "cloudfront:Get*",
      "cloudfront:List*",
      "acm:Describe*",
      "acm:List*",
      "acm:GetCertificate",
      "route53:Get*",
      "route53:List*"
    ]
    resources = ["*"]
  }

  statement {
    #read-only mirror of ECRManage (ecr module)
    sid = "ECRReadOnly"
    actions = [
      "ecr:Describe*",
      "ecr:List*",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy"
    ]
    resources = ["*"]
  }

  statement {
    #read-only mirror of IAMForClusterRoles - no Create/Delete/Attach/
    #PutRolePolicy/PassRole anywhere; plan only ever reads existing roles
    #and policies to detect drift, never mutates or passes them
    sid = "IAMReadOnly"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListRoleTags",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviders"
    ]
    resources = ["*"]
  }

  statement {
    #read the state file only - no PutObject, since plan never writes
    #a new state file (that only happens on apply)
    sid = "StateBackendReadOnly"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.terraform_state_bucket}",
      "arn:aws:s3:::${var.terraform_state_bucket}/*"
    ]
  }

  statement {
    #NOT read-only, and deliberately kept: Terraform's S3 backend still
    #acquires a real DynamoDB lock during `init`/`plan`, even though the
    #operation against actual AWS resources is entirely read-only. This
    #is a backend-locking requirement, not scope creep.
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

resource "aws_iam_policy" "terraform_plan" {

  name = "${var.project_name}-${var.environment}-terraform-plan-policy"

  policy = data.aws_iam_policy_document.terraform_plan_permissions.json  
}

resource "aws_iam_role_policy_attachment" "terraform_plan" {

  role = aws_iam_role.terraform_plan.name

  policy_arn = aws_iam_policy.terraform_plan.arn
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
}

resource "aws_iam_policy" "deployment" {

  name = "${var.project_name}-${var.environment}-deployment-policy"

  policy = data.aws_iam_policy_document.deployment_permissions.json
}

resource "aws_iam_role_policy_attachment" "deployment" {

  role = aws_iam_role.deployment.name

  policy_arn = aws_iam_policy.deployment.arn
}


# EKS ACCESS ENTRY (kubernetes RBAC mapping for the deployment role.)
#
# IAM alone only gets us authenticated to the cluster - it says nothing about what you're
# authorised to do once connected. Kubernetes RBAC is a separate layer,
# and eks access entries are the modern, aws-recommended way to map an 
# IAM principal to that RBAC layer.  Without this, `helm upgrade`/`kubectl` calls using
# this role's kubeconfig would fail with "Unauthorized" against the
# Kubernetes API, regardless of how correct the IAM policy above is.

resource "aws_eks_access_entry" "deployment" {
  
  cluster_name = var.cluster_name

  principal_arn = aws_iam_role.deployment.arn

  type = "STANDARD"
}

#Scoped to just the app namespaces (one per service), not cluster-wide -
#AmazonEKSEditPolicy grants create/update/delete on workloads, services,
#secrets, configmaps etc. within the given namespaces (exactly what a
#helm upgrade needs), but not cluster-scoped resources or RBAC itself.

resource "aws_eks_access_policy_association" "deployment_edit" {

  cluster_name = var.cluster_name

  principal_arn = aws_iam_role.deployment.arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type = "namespace"
    namespaces = var.app_namespaces
  }

  depends_on = [aws_eks_access_entry.deployment]
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