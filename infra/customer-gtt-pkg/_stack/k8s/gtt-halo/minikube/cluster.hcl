# cluster.hcl — included by all chart units under this cluster directory.
# Declares the kubeconfig dependency so chart units get correct ordering for free.
# Structural boilerplate only: no deployment-specific values permitted here.

dependency "kubeconfig" {
  config_path = "${dirname(find_in_parent_folders("cluster.hcl"))}/kubeconfig"
  mock_outputs = {
    result = "mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}
