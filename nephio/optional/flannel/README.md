# flannel

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] flannel`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree flannel`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init flannel
kpt live apply flannel --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
