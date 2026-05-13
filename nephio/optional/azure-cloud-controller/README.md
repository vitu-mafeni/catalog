# azure-cloud-controller

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] azure-cloud-controller`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree azure-cloud-controller`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init azure-cloud-controller
kpt live apply azure-cloud-controller --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
