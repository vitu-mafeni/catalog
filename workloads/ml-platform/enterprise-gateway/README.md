# enterprise-gateway

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] enterprise-gateway`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree enterprise-gateway`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the packages
```
kpt live init enterprise-gateway
kpt live apply enterprise-gateway --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
