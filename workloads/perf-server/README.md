# perf-server

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] perf-server`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree perf-server`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init perf-server
kpt live apply perf-server --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
