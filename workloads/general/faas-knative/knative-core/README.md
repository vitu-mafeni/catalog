# knative-core

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] knative-core`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree knative-core`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init knative-core
kpt live apply knative-core --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
