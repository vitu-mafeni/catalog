# k8s-dra-driver-gpu

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] k8s-dra-driver-gpu`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree k8s-dra-driver-gpu`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init k8s-dra-driver-gpu
kpt live apply k8s-dra-driver-gpu --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
