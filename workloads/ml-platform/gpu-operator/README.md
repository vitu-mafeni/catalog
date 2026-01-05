# gpu-operator

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] gpu-operator`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree gpu-operator`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init gpu-operator
kpt live apply gpu-operator --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
