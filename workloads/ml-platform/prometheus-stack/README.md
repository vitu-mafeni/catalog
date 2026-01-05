# prometheus-stack

## Description
This will install prometheus-community/kube-prometheus-stack v80.10.0 and app v0.87.1.
Update the Helm-release file to update the version

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] prometheus-stack`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree prometheus-stack`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init prometheus-stack
kpt live apply prometheus-stack --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
