# remote-cluster-provisioner

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] remote-cluster-provisioner`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree remote-cluster-provisioner`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init remote-cluster-provisioner
kpt live apply remote-cluster-provisioner --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
