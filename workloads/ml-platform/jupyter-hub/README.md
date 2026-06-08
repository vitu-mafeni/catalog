# jupyter-hub

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] jupyter-hub`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree jupyter-hub`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init jupyter-hub
kpt live apply jupyter-hub --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
