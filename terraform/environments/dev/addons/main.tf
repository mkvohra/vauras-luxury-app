module "addons" {

  source = "../../../modules/addons"

  project_name = var.project_name

  environment = var.environment

  cluster_oidc_provider_arn = 
    data.terraform_remote_state.eks.outputs.cluster_oidc_provider_arn

  cluster_oidc_issuer_url =
    data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url  

  domain_name = var.domain_name  
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