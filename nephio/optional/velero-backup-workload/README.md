# velero-backup

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] velero-backup`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree velero-backup`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init velero-backup
kpt live apply velero-backup --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
