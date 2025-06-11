# longhorn-storage-provisioner

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] longhorn-storage-provisioner`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree longhorn-storage-provisioner`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init longhorn-storage-provisioner
kpt live apply longhorn-storage-provisioner --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
