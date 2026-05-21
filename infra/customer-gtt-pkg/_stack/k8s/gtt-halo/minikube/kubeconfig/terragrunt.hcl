include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  up = include.root.locals.unit_params

  tg_script = try(local.up.kubeconfig_cli_command, "") != "" ? "kubeconfig-from-cli" : "kubeconfig-from-sops"

  config_files = [
    "${include.root.locals.stack_root}/infra/customer-gtt-pkg/_config/customer-gtt-pkg.yaml",
  ]
  config_hash = sha256(join("", [for f in local.config_files : filesha256(f)]))
}

terraform {
  # unit_type: k8s_kubeconfig
  source = "${include.root.locals.modules_dir}/null_resource__run-script"
}

inputs = {
  trigger    = local.config_hash
  script_dir = "${include.root.locals._tg_scripts}/k8s/${local.tg_script}"
}
