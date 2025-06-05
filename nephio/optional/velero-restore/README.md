# velero-restore

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] velero-restore`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree velero-restore`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init velero-restore
kpt live apply velero-restore --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
