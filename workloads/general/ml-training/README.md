# ml-training

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] ml-training`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree ml-training`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init ml-training
kpt live apply ml-training --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
