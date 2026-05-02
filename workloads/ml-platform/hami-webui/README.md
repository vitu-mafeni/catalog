# hami-webui

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] hami-webui`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree hami-webui`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init hami-webui
kpt live apply hami-webui --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
