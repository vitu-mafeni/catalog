# olm

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] olm`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree olm`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init olm
kpt live apply olm --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
