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

  # harbor-registry-secret is created by the minio unit; not here.
  # model-training-secrets is created here once; trainer and evaluator reference it.
  # AWS_ACCESS_KEY_ID/SECRET = MinIO credentials: MLflow uses s3:// URIs via
  # MLFLOW_S3_ENDPOINT_URL (in-cluster MinIO), not real AWS S3.
  k8s_secrets = {
    "model-training-secrets" = {
      MLFLOW_BACKEND_STORE_URI       = local.ups.mlflow_backend_store_uri
      MLFLOW_ARTIFACT_ROOT           = local.ups.mlflow_artifact_root
      MLFLOW_S3_ENDPOINT_URL         = local.ups.mlflow_s3_endpoint_url
      AWS_ACCESS_KEY_ID              = local.ups.minio_access_key
      AWS_SECRET_ACCESS_KEY          = local.ups.minio_secret_key
      MINIO_ACCESS_KEY               = local.ups.minio_access_key
      MINIO_SECRET_KEY               = local.ups.minio_secret_key
      MINIO_TRAINING_DATASET_BUCKET  = local.up.minio_training_dataset_bucket
      MINIO_MODELS_BUCKET            = local.up.minio_models_bucket
      MINIO_TRAINING_RESULTS_BUCKET  = local.up.minio_training_results_bucket
      MINIO_TRAIN_EVAL_CONFIG_BUCKET = local.up.minio_train_eval_config_bucket
      AZURE_OPENAI_ENDPOINT          = local.ups.azure_openai_endpoint
      AZURE_OPENAI_API_KEY           = local.ups.azure_openai_api_key
      AZURE_OPENAI_DEPLOYMENT_NAME   = local.ups.azure_openai_deployment_name
      AZURE_OPENAI_API_VERSION       = local.ups.azure_openai_api_version
      HF_TOKEN                       = local.ups.hf_token
    }
  }
}
