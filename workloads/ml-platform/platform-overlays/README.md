# platform-overlays

## Description
This contains configurations of the ML platform components, it has to be installed after all other components in .ml-platform are deployed

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] platform-overlays`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree platform-overlays`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init platform-overlays
kpt live apply platform-overlays --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
