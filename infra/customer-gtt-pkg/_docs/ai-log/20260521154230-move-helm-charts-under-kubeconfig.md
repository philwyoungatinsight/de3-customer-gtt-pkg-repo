# Move Helm Charts Under kubeconfig/charts/

## Summary

All Helm chart Terragrunt units moved from being siblings of `kubeconfig/` at the cluster
root to living inside `kubeconfig/charts/` at arbitrary depth. This enables logical grouping
of charts (e.g. `model-training/{server,trainer,evaluator}/`) and makes the directory tree
self-documenting: everything under `kubeconfig/charts/` connects to that cluster.
`cluster.hcl` was fixed so the kubeconfig/tunnel dependency paths resolve correctly at any
nesting depth, not just from direct siblings.

## Changes

- **`cluster.hcl` (chicago-dell + minikube)** — replaced `${path_relative_to_include()}/kubeconfig`
  with `${dirname(find_in_parent_folders("cluster.hcl"))}/kubeconfig`. The old formula broke
  for charts more than one directory level from the cluster root.
- **`customer-gtt-pkg.yaml`** — added `kubeconfig/charts` anchor entry setting `_provider: helm`
  and `_modules_dir: k8s-pkg/_modules` for each cluster, overriding the null provider
  inherited from `kubeconfig/`. Replaced all old sibling chart paths with new `kubeconfig/charts/`
  paths. Grouped model-training charts under `kubeconfig/charts/model-training/`.
- **Chart unit directories** — moved all 8 chart units (7 chicago-dell + 1 minikube) to new
  paths. `terragrunt.hcl` content unchanged; only the filesystem location changed.
- **`tunnel/terragrunt.hcl`, `kubeconfig/terragrunt.hcl` (both clusters)** — fixed stale
  `de3-customer-gtt-pkg` package name references left over from the 1.2.0 rename.
- **`version_history.md`** — bumped to 1.3.0.

## Root Cause

`path_relative_to_include()` in `cluster.hcl` returns the child unit's path relative to
the include file's directory. For a chart at `chicago-dell/minio/` this is `minio`, making
the dependency `minio/kubeconfig` which resolves correctly (Terragrunt resolves relative to
the child, so effectively `../kubeconfig`). For a chart at `chicago-dell/kubeconfig/charts/minio/`
it becomes `kubeconfig/charts/minio`, resolving to `chicago-dell/kubeconfig/charts/minio/kubeconfig`
which doesn't exist. The fix anchors the path explicitly from the cluster root via
`find_in_parent_folders`.

## Notes

- The `kubeconfig/charts` config anchor in YAML is the key invariant: any unit at any depth
  under `kubeconfig/charts/` inherits `_provider: helm`, overriding the null provider at
  `kubeconfig/`. New charts only need chart-specific keys (`release_name`, `chart_subpath`).
- State backend keys changed on move (GCS prefix = `rel_path`). Existing deployed releases
  continue running in the cluster; on next apply Terragrunt will see new paths as fresh units
  and re-install (destroy-old + apply-new accepted by user).
- The pattern generalises: any future k8s tool can live at any depth under the cluster root
  and inherit cluster connectivity by including `cluster.hcl`.
