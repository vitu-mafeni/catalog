# cluster-api-azure

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] cluster-api-azure`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree cluster-api-azure`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init cluster-api-azure
kpt live apply cluster-api-azure --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/



