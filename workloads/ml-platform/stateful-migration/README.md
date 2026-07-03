# stateful-migration

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] stateful-migration`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree stateful-migration`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init stateful-migration
kpt live apply stateful-migration --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
