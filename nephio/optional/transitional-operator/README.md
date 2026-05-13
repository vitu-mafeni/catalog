# transitional-operator

## Description

The **transitional-operator** is a Kubernetes controller that manages workload migration and checkpointing across clusters in a Nephio-based environment. It watches custom resources (`Checkpoint`, `ClusterPolicy`, `NodeHealth`, `PackagePolicy`) under the `transition.dcnlab.ssu.ac.kr` API group and orchestrates:

- **Container checkpointing** – snapshots running containers into OCI images pushed to a registry
- **Cluster-to-cluster package transition** – moves kpt packages between source and target clusters
- **Node health monitoring** – tracks node conditions and heartbeat faults
- **Policy-driven scheduling** – selects target clusters based on `ClusterPolicy` rules

The controller image is hosted at `docker.io/vitu1/transition-operator:debug`.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Kubernetes cluster with `kubectl` access | Controller runs in `transition-operator-system` namespace |
| MinIO (or S3-compatible store) | Used to store checkpoint state |
| OCI-compatible container registry | Images are pushed here during checkpointing |
| Gitea / Porch-compatible Git server | Used to store kpt package state |
| `kpt` CLI ≥ v1.0 | Required to fetch and apply the package |

---

## Required Secrets

Before applying the package you must create the three secrets below in the **`transition-operator-system`** namespace. The controller reads all sensitive configuration exclusively from these secrets.

### 1. MinIO credentials — `transition-operator-minio-secret`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: transition-operator-minio-secret
  namespace: transition-operator-system
type: Opaque
stringData:
  MINIO_ENDPOINT: "http://minio.example.com:9000"   # MinIO endpoint URL
  MINIO_ACCESS_KEY: "your-access-key"
  MINIO_SECRET_KEY: "your-secret-key"
  MINIO_BUCKET: "transition-checkpoints"             # bucket must already exist
```

### 2. Container registry credentials — `transition-operator-reg-credentials`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: transition-operator-reg-credentials
  namespace: transition-operator-system
type: Opaque
stringData:
  username: "your-registry-username"      # also used as the REPOSITORY value
  password: "your-registry-password"
  registry: "docker.io"                   # registry host, e.g. docker.io or ghcr.io
```

> **Note:** A copy of this secret named `reg-credentials` must also exist in the **`default`** namespace (or whichever namespace is set via `SECRET_NAMESPACE_REF`). The controller references it by name when pulling/pushing checkpoint images.

### 3. Git server credentials — `transition-operator-git-secret`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: transition-operator-git-secret
  namespace: transition-operator-system
type: Opaque
stringData:
  GIT_SERVER_URL: "http://gitea.example.com"   # base URL of the Gitea/Porch server
  GIT_SECRET_NAME: "gitea-credentials"         # name of the secret used to auth with the Git server
  GIT_SECRET_NAMESPACE: "default"              # namespace where that secret lives
```

---

## Environment Variables Reference

The following table lists every environment variable the controller reads at runtime. Variables sourced from secrets are managed automatically once the secrets above are created; the two plain values can be overridden directly in [crds/operator.yaml](crds/operator.yaml).

| Variable | Source | Description |
|---|---|---|
| `MINIO_ENDPOINT` | `transition-operator-minio-secret` | URL of the MinIO/S3 endpoint |
| `MINIO_ACCESS_KEY` | `transition-operator-minio-secret` | MinIO access key |
| `MINIO_SECRET_KEY` | `transition-operator-minio-secret` | MinIO secret key |
| `MINIO_BUCKET` | `transition-operator-minio-secret` | Bucket used for checkpoint storage |
| `REPOSITORY` | `transition-operator-reg-credentials` (key: `username`) | Registry username / repository prefix |
| `REGISTRY_PASSWORD` | `transition-operator-reg-credentials` (key: `password`) | Registry password |
| `REGISTRY_URL` | `transition-operator-reg-credentials` (key: `registry`) | Registry host (e.g. `docker.io`) |
| `SECRET_NAME_REF` | plain value (`reg-credentials`) | Name of the registry pull-secret in workload namespaces |
| `SECRET_NAMESPACE_REF` | plain value (`default`) | Namespace of the registry pull-secret |
| `GIT_SERVER_URL` | `transition-operator-git-secret` | Base URL of the Git/Porch server |
| `GIT_SECRET_NAME` | `transition-operator-git-secret` | Name of the Git auth secret |
| `GIT_SECRET_NAMESPACE` | `transition-operator-git-secret` | Namespace of the Git auth secret |
| `HEARTBEAT_FAULT_DELAY` | plain value (`15`) | Seconds to wait before marking a node faulty after missed heartbeat |
| `POD_NAMESPACE` | `fieldRef: metadata.namespace` | Injected automatically — do not set manually |

---

## Usage

### 1. Fetch the package

```bash
kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] transitional-operator
```

Details: https://kpt.dev/reference/cli/pkg/get/

### 2. View package content

```bash
kpt pkg tree transitional-operator
```

Details: https://kpt.dev/reference/cli/pkg/tree/

### 3. Create the namespace and secrets

```bash
kubectl create namespace transition-operator-system

# MinIO credentials
kubectl apply -f minio-secret.yaml

# Registry credentials (in operator namespace)
kubectl apply -f reg-credentials-secret.yaml

# Registry pull-secret copy in the default namespace (or SECRET_NAMESPACE_REF)
kubectl create secret docker-registry reg-credentials \
  --docker-server=docker.io \
  --docker-username=<username> \
  --docker-password=<password> \
  --namespace=default

# Git server credentials
kubectl apply -f git-secret.yaml
```

### 4. (Optional) Customise plain env values

If you need to change `SECRET_NAME_REF`, `SECRET_NAMESPACE_REF`, or `HEARTBEAT_FAULT_DELAY` from their defaults, edit [crds/operator.yaml](crds/operator.yaml) before applying:

```yaml
- name: SECRET_NAME_REF
  value: "reg-credentials"        # name of registry pull-secret in workload namespaces
- name: SECRET_NAMESPACE_REF
  value: "default"                # namespace of that pull-secret
- name: HEARTBEAT_FAULT_DELAY
  value: "15"                     # seconds before a silent node is marked faulty
```

### 5. Apply the package

```bash
kpt live init transitional-operator
kpt live apply transitional-operator --reconcile-timeout=2m --output=table
```

Details: https://kpt.dev/reference/cli/live/

### 6. Verify the controller is running

```bash
kubectl get pods -n transition-operator-system
kubectl logs -n transition-operator-system \
  deployment/transition-operator-controller-manager -c manager
```

The pod should reach `Running` state. The manager logs will confirm it has connected to MinIO, the registry, and the Git server.

---

## Custom Resources

Once the operator is running you can create the following resources:

| Kind | API Group | Purpose |
|---|---|---|
| `Checkpoint` | `transition.dcnlab.ssu.ac.kr/v1` | Snapshot a pod's containers and push to registry |
| `ClusterPolicy` | `transition.dcnlab.ssu.ac.kr/v1` | Define preferred/avoided target clusters for package transitions |
| `NodeHealth` | `transition.dcnlab.ssu.ac.kr/v1` | Track per-node health and resource metrics |
| `PackagePolicy` | `transition.dcnlab.ssu.ac.kr/v1` | Policy for individual package management |

See [crds/crds.yaml](crds/crds.yaml) for the full OpenAPI schemas.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Pod in `CrashLoopBackOff` | Missing or misnamed secret — check `kubectl describe pod` for env injection errors |
| `failed to connect to MinIO` in logs | Wrong `MINIO_ENDPOINT`, bucket does not exist, or network policy blocking egress |
| Checkpoint stuck in `Progressing` | Registry credentials wrong or `reg-credentials` pull-secret missing in target namespace |
| Node marked faulty immediately | `HEARTBEAT_FAULT_DELAY` too low or node agent not running |
