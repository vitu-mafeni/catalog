# kt-cloud-operator

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] kt-cloud-operator`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree kt-cloud-operator`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init kt-cloud-operator
kpt live apply kt-cloud-operator --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
