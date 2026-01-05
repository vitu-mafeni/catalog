# kubeflow

## Description
Installs all kubeflow components in git branch v1.11-branch.
There is need to add registry credentials if images fails to pull successfully

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: regcred
  namespace: kubeflow
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: BASE64_ENCODED_JSON
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
  namespace: kubeflow
imagePullSecrets:
  - name: regcred

```

To add BASE64_ENCODED_JSON for a kubernetes.io/dockerconfigjson Secret correctly and safely, follow the steps below. This is the exact, canonical process Kubernetes expects.
### 1. Generate the Docker Config JSON
First, ensure you are logged in:
```bash
docker login <REGISTRY>
```
This creates or updates:
```bash
$HOME/.docker/config.json
```
Example content (simplified):
```json
{
  "auths": {
    "ghcr.io": {
      "auth": "dXNlcjpwYXNzd29yZA=="
    }
  }
}
```
### 2. Base64-Encode the File
**Do not encode individual fields.**
Encode the entire file as-is.
```bash
base64 -w 0 $HOME/.docker/config.json
```
Notes:
- -w 0 prevents line wrapping (required for YAML)
The output is your __BASE64_ENCODED_JSON.__

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] kubeflow`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree kubeflow`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init kubeflow
kpt live apply kubeflow --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
