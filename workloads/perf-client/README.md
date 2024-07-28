# perf-client

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] perf-client`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree perf-client`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init perf-client
kpt live apply perf-client --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
