include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "cluster" {
  path = find_in_parent_folders("cluster.hcl")
}

terraform {
  # unit_type: helm_release
  source = "${include.root.locals.modules_dir}/helm_release"
}

locals {
  up  = include.root.locals.unit_params
  ups = include.root.locals.unit_secret_params
}

inputs = {
  release_name     = local.up.release_name
  namespace        = local.up.namespace
  create_namespace = try(local.up.create_namespace, false)
  chart_path       = "${local.up.helm_charts_base_dir}/${local.up.chart_subpath}"
  wait             = try(local.up.chart_wait, true)
  timeout          = try(tonumber(local.up.chart_timeout), 300)
  common_tags      = include.root.locals.common_tags

  k8s_secrets = {
    "minio-root-secrets" = {
      MINIO_ROOT_USER     = local.ups.minio_root_user
      MINIO_ROOT_PASSWORD = local.ups.minio_root_password
    }
  }

  k8s_docker_secrets = {
    "harbor-registry-secret" = local.ups.harbor_dockerconfigjson
  }
}
