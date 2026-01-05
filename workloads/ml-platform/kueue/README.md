# kueue

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] kueue`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree kueue`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init kueue
kpt live apply kueue --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
