# quota-scaling-app

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] quota-scaling-app`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree quota-scaling-app`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init quota-scaling-app
kpt live apply quota-scaling-app --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
