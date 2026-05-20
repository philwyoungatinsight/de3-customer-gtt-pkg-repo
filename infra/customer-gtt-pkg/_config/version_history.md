## 1.2.0  (2026-05-20, git: 33197b4)
- Rename package: de3-customer-gtt-pkg → customer-gtt-pkg
- Add external packages: _framework-pkg, de3-gui-pkg, k8s-pkg
- New GCS backend bucket halo-bucket-20260520 in project customer-gtt-halo-20260520
- Update _requires_capability and _modules_dir/_tg_scripts_dir to k8s-pkg

## 1.1.0  (2026-05-19, git: df901fe)
- Add tunnel unit for chicago-dell: SSH port-forward via ensure-tunnel tg-script
- Fix missing _modules_dir on all clusters (helm_release lives in de3-k8s-pkg/_modules)
- Fix missing _tg_scripts_dir on all clusters (tg-scripts live in de3-k8s-pkg/_tg_scripts)

## 1.0.0  (2026-05-19, git: 5dda132)
- Initial release: 7 GTT Halo Helm charts on chicago-dell, minikube dev cluster
