# kai-scheduler

## Description
This is Kai-scheduler v0.12.2
Update the helm-release.yaml on spec.chart.spec.version to change version

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] kai-scheduler`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree kai-scheduler`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init kai-scheduler
kpt live apply kai-scheduler --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
