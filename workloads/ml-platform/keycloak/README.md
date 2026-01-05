# keycloak

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] keycloak`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree keycloak`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init keycloak
kpt live apply keycloak --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
