# ml-platform-admin

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] ml-platform-admin`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree ml-platform-admin`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init ml-platform-admin
kpt live apply ml-platform-admin --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
