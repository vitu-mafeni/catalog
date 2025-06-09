# wordpress-app

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] wordpress-app`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree wordpress-app`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init wordpress-app
kpt live apply wordpress-app --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
