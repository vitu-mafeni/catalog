# nfs-provisioner

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] nfs-provisioner`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree nfs-provisioner`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init nfs-provisioner
kpt live apply nfs-provisioner --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
