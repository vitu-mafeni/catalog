# argo-cd-core

## Description
kpt package for deploying argocd package

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] argo-cd-core`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree argo-cd-core`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init argocd
kpt live apply argocd --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
