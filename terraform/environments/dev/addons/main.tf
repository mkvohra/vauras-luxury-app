
# READING REMOTE STATE OF EKS 

data "terraform_remote_state" "eks" {

  backend = "s3"

  config = {

    bucket = "vauras-terraform-state"

    key = "dev/eks/terraform.tfstate"

    region = "ap-south-1"
  }
}

#===================================================================================================

# READING REMOTE STATE OF SECRETS-MANAGER
# (needed to scope ESO's IAM policy to the actual app-secrets ARN,
# rather than a string-constructed guess - also signals the real
# addons-depends-on-secrets-manager relationship to infra.yml's
# dependency-level detection)

data "terraform_remote_state" "secrets_manager" {

  backend = "s3"

  config = {

    bucket = "vauras-terraform-state"

    key = "dev/secrets-manager/terraform.tfstate"

    region = "ap-south-1"
  }
}

#==================================================================================================================


module "addons" {

  source = "../../../modules/addons"

  project_name = var.project_name

  environment = var.environment

  cluster_oidc_provider_arn = 
    data.terraform_remote_state.eks.outputs.cluster_oidc_provider_arn

  cluster_oidc_issuer_url =
    data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url  

  domain_name = var.domain_name 

  app_secret_arn = data.terraform_remote_state.secrets_manager.outputs.secret_arn
}


#----------------------------------------------------------------------------------------------------------
# APPLICATION NAMESPACES
#
# These namespaces are cluster-scoped Kubernetes resources, so they are
# created by the Terraform addons root, which has cluster-admin access via
# the EKS bootstrap cluster-creator permissions. backend.yml therefore does
# not need --create-namespace, and the deployment role does not need
# cluster-scoped namespace-create permissions.

resource "kubernetes_namespace_v1" "app" {

  for_each = toset(var.app_namespaces)

  metadata {
    name = each.value

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "project"                      = var.project_name
      "environment"                  = var.environment
    }
  }
}



#RELEASE CHARTS 

# (METRICS SERVER HELM CHART)

resource "helm_release" "metrics_server" {

  name = "metrics-server" 

  repository = "https://kubernetes-sigs.github.io/metrics-server"

  chart = "metrics-server"

  namespace = "kube-system"

  create_namespace = false 
}


#(AWS-LOAD-BALANCER HELM CHART)

resource "helm_release" "aws_load_balancer_controller" {

  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"

  chart = "aws-load-balancer-controller"

  namespace = "kube-system"

  create_namespace = false

  set {
    name = "clusterName"

    value = data.terraform_remote_state.eks.outputs.cluster_name
  }   

  set {
    name = "serviceAccount.create"

    value = true
  }

  set {
    name = "serviceAccount.name"

    value = "aws-load-balancer-controller"
  }

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"

    value = module.addons.aws_lb_controller_role_arn
  }

  depends_on = [module.addons]
}



#( CLUSTER AUTOSCALER HELM CHART)

resource "helm_release" "cluster_autoscaler" {
  name = "cluster-autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"

  chart = "cluster-autoscaler"
  
  namespace = "kube-system"

  create_namespace = false

  set {
    name = "autoDiscovery.clusterName"

    value = data.terraform_remote_state.eks.outputs.cluster_name
  }

  set {
    name = "rbac.serviceAccount.create"

    value = true
  }

  set {
    name = "rbac.serviceAccount.name"

    value = "cluster-autoscaler"
  }

  set {
    name = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"

    value = module.addons.cluster_autoscaler_role_arn
  }

  depends_on = [module.addons]

}


# ( EXTERNAL-DNS HELM CHART ) 

resource "helm_release" "external_dns" {

  name = "external-dns"

  repository = "https://kubernetes-sigs.github.io/external-dns/"

  chart = "external-dns"

  namespace = "kube-system"

  create_namespace = false

  set {
    name = "provider"
    
    value = "aws"
  }

  set {
    name = "aws.zoneType"

    value = "public"
  }

  set {
    name = "domainFilters[0]"

    value = var.domain_name
  }

  set {
    name = "txtOwnerId"

    value = data.terraform_remote_state.eks.outputs.cluster_name
  }

  # "upsert-only" never deletes records ExternalDNS didn't create, and never
  # deletes records if the Ingress goes away first -- safer default while
  # we're still testing this. Switch to "sync" once trusted end-to-end.

  set {
    name = "policy"

    value = "upsert-only"
  }

  set {
    name = "serviceAccount.create"

    value = true
  }

  set {
    name = "serviceAccount.name"

    value = "external-dns"
  }

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"

    value = module.addons.external_dns_role_arn
  }

  depends_on = [module.addons]

}

# (EXTERNAL SECRETS OPERATOR HELM CHART )

resource "helm_release" "external_secrets" {

  name = "external-secrets"

  repository = "https://charts.external-secrets.io"

  chart = "external-secrets"

  namespace = "kube-system"

  create_namespace = false

  set {
    name = "installCRDs"

    value = true
  }

  set {
    name = "serviceAccount.create"

    value = true
  }

  set {
    name = "serviceAccount.name"

    value = "external-secrets"
  }

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"

    value = module.addons.external_secrets_role_arn
  }

  depends_on = [module.addons]
}

# ONE cluster-wide SecretStore, not one per namespace - both auth and
# cart use the identical AWS backend connection (same ESO role, same
# region), so there's nothing to gain from duplicating this per
# namespace. Referenced by an ExternalSecret in each service's own
# namespace (see helm/common-chart/templates/externalsecret.yaml).


resource "kubernetes_manifest" "cluster_secret_store" {

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"

    metadata = {
      name = "clusters-secret-store"
    } 
    
    spec = {
      provider = {
        aws = {
          service = "SecretManager"
          region = var.aws_region

          auth = {
            jwt = {
              serviceAccountRef = {
                name = "external-secrets"
                namespace = "kube-system"
              }
            }
          }
        }
      }
    }
  }

  # the ClusterSecretStore CRD only exists once ESO's Helm release has
  # installed it - applying this before that would fail
  depends_on = [helm_release.external_secrets]
}