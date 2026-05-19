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

  chart_values = {
    "hfModelCache.enabled" = tostring(try(local.up.hf_model_cache_enabled, false))
    "hfModelCache.storage" = try(local.up.hf_model_cache_size, "10Gi")
    "gpu.enabled"          = tostring(try(local.up.gpu_enabled, false))
  }

  k8s_secrets = {
    "model-training-secrets" = {
      MINIO_ACCESS_KEY              = local.ups.minio_access_key
      MINIO_SECRET_KEY              = local.ups.minio_secret_key
      MINIO_TRAINING_DATASET_BUCKET = try(local.up.minio_training_dataset_bucket, "")
      MINIO_MODELS_BUCKET           = try(local.up.minio_models_bucket, "")
      MINIO_TRAINING_RESULTS_BUCKET = try(local.up.minio_training_results_bucket, "")
      AWS_ACCESS_KEY_ID             = local.ups.aws_access_key_id
      AWS_SECRET_ACCESS_KEY         = local.ups.aws_secret_access_key
      HF_TOKEN                      = local.ups.hf_token
    }
  }
}
