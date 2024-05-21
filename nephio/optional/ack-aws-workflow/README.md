# ack-aws-resources

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] ack-aws-resources`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree ack-aws-resources`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init ack-aws-resources
kpt live apply ack-aws-resources --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
