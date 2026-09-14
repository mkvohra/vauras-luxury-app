#AWS LOAD BALANCER CONTROLLER POLICY (importing from github)

data "http" "aws_lb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"  
}

# CREATING IAM POLICY (naming the above permission policy)

resource "aws_iam_policy" "aws_lb_controller" {
  name = "${var.project_name}-${var.environment}-aws-lb-controller-policy"

  policy = data.http.aws_lb_controller_policy.response_body  
}

#AWS LB CONTROLLER TRUST POLICY

data "aws_iam_policy_document" "aws_lb_controller_assume_role" {

  statement {

    actions =[
      "sts:AssumeRoleWithWebIdentity"  
    ]

    principals {
      type = "Federated"

      identifiers = [
        var.cluster_oidc_provider_arn
      ]  
    }

    condition {
      test = "StringEquals"
      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub"

      values  = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }

    condition {
      test = "StringEquals"

      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud"

      values = ["sts.amazonaws.com"]
    }
  }  
}

#AWS LB CONTROLLER IAM ROLE
resource "aws_iam_role" "aws_lb_controller" {
  name = "${var.project_name}-${var.environment}-aws-lb-controller-role"

  assume_role_policy = data.aws_iam_policy_document.aws_lb_controller_assume_role.json  
}

#ATTACH POLICY

resource "aws_iam_role_policy_attachment" "aws_lb_controller" {
  role = aws_iam_role.aws_lb_controller.name

  policy_arn = aws_iam_policy.aws_lb_controller.arn  
}

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#CLUSTER AUTOSCALER POLICY

data "aws_iam_policy_document" "cluster_autoscaler" {

  statement {
    actions = [
      "autoscaling:SetDesiredCapacity",  
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = ["*"]
  } 

  statement {

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "ec2:DescribeLaunchTemplateVersions"  
    ]

    resources = ["*"]
  }
}

# CREATE POLICY 

resource "aws_iam_policy" "cluster_autoscaler" {

  name = "${var.project_name}-${var.environment}-cluster-autoscaler-policy" 

  policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

#Cluster Autoscaler Trust Policy

data "aws_iam_policy_document" "cluster_autoscaler_assume_role" {
  statement {
    actions =[
      "sts:AssumeRoleWithWebIdentity"  
    ]

    principals {
      type = "Federated"

      identifiers = [
        var.cluster_oidc_provider_arn
      ]
    }

    condition {
      test = "StringEquals"

      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:kube-system:cluster-autoscaler"
      ]  
    }

    condition {
      test = "StringEquals"

      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud"

      values = ["sts.amazonaws.com"]
    }
  }  
}


#CREATE CLUSTER AUTOSCALER ROLE

resource "aws_iam_role" "cluster_autoscaler" {

  name = "${var.project_name}-${var.environment}-cluster-autoscaler-role"  

  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role.json
}

# ATTACH POLICY 

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {

  role = aws_iam_role.cluster_autoscaler.name

  policy_arn = aws_iam_policy.cluster_autoscaler.arn

}

#----------------------------------------------------------------------------------------------------------------------------------------------------

#EXTERNAL DNS COTROLLER 

#LOOK UP THE HOSTED ZONE SO WE CAN SCOPE THE IAM POLICY TO JUST THIS ZONE

data "aws_route53_zone" "this" {

  name = var.domain_name

  private_zone = false
}

#EXTERNAL DNS POLICY (scoped to the vauras.xyz zone only, not "*") [Mention the permissions]

data "aws_iam_policy_document" "external_dns" {

  statement {
    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.this.zone_id}"
    ]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]

    resources = ["*"]
  }
}

# CREATE POLICY (naming the prmission policy)

resource "aws_iam_policy" "external_dns" {

  name = "${var.project_name}-${var.environment}-external-dns-policy"

  policy = data.aws_iam_policy_document.external_dns.json
}

# EXTERNAL-DNS TRUST POLICY

data "aws_iam_policy_document" "external_dns_assume_role" {

  statement {

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        var.cluster_oidc_provider_arn
      ]
    }

    condition {
      test = "StringEquals"

      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:kube-system:external-dns"
      ]
    }

    condition {
      test = "StringEquals"

      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud"

      values = ["sts.amazonaws.com"]
    }
  }
}

#EXTERNAL-DNS IAM ROLE

resource "aws_iam_role" "external_dns" {

  name = "${var.project_name}-${var.environment}-external-dns-role"

  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role.json
}

# ATTACH POLICY

resource "aws_iam_role_policy_attachment" "external_dns" {

  role = aws_iam_role.external_dns.name

  policy_arn = aws_iam_policy.external_dns.arn
}


#--------------------------------------------------------------------------------------------------------------------

# EXTERNAL SECRETS OPERATOR (ESO)
#
# reads the project's app-secrets from AWS secrets manager and sync them
# into kubernetes secrets. Scoped to only that one secret - not
#secretsmanager:* generally - since that's the only thing ESO needs to
# do here.

# ESO POLICY (scoped to just this project/environment's secret, not "*")

data "aws_iam_policy_document" "external_secrets" {

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      var.app_secret_arn
    ]
  }
}

resource "aws_iam_policy" "external_secrets" {

  name = "${var.project_name}-${var.environment}-external-secrets-policy"

  policy = data.aws_iam_policy_document.external_secrets.json
}

# EXTERNAL-SECRETS TRUST POLICY

data "aws_iam_policy_document" "external_secrets_assume_role" {

  statement {

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        var.cluster_oidc_provider_arn
      ]
    }

    condition {
      test = "StringEquals"

      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:kube-system:external-secrets"
      ]
    }

    condition {
      test = "StringEquals"

      variable = "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud"

      values = ["sts.amazonaws.com"]
    }
  }
}

#EXTERNAL-SECRETS IAM ROLE

resource "aws_iam_role" "external_secrets" {
  
  name = "${var.project_name}-${var.environment}-external-secrets-role"

  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json
}

# ATTACH POLICY

resource "aws_iam_role_policy_attachment" "external_secrets" {

  role = aws_iam_role.external_secrets.name

  policy_arn = aws_iam_policy.external_secrets.arn
}