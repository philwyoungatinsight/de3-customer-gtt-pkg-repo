include "root"    { path = find_in_parent_folders("root.hcl"); expose = true }
include "cluster" { path = find_in_parent_folders("cluster.hcl") }

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
    "model-training-secrets" = {
      MLFLOW_BACKEND_STORE_URI = local.ups.mlflow_backend_store_uri
      MLFLOW_ARTIFACT_ROOT     = local.ups.mlflow_artifact_root
      AWS_ACCESS_KEY_ID        = local.ups.aws_access_key_id
      AWS_SECRET_ACCESS_KEY    = local.ups.aws_secret_access_key
    }
  }
}
