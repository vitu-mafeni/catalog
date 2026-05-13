# checkpoint-agent

## Description

The checkpoint-agent is a DaemonSet that runs on every worker node and manages Kubernetes container checkpoints. It:

- Watches `/var/lib/kubelet/checkpoints` for new checkpoint archives created by the kubelet
- Uploads checkpoint files to a MinIO object store using SHA256 checksum deduplication (skips unchanged files)
- Periodically syncs checkpoint files from MinIO back to nodes so checkpoints are available cluster-wide
- Sends a heartbeat to a central controller on each tick with node metrics (CPU, memory, OS, architecture) and CAPI cluster annotations

## Prerequisites

- Kubernetes 1.25+ with the `ContainerCheckpoint` feature gate enabled on the kubelet
- A running MinIO instance reachable from the cluster nodes
- A heartbeat controller endpoint (can be a simple HTTP server that accepts POST `/heartbeat`)
- Container image `vitu1/checkpoint-agent:v1.0.0` accessible from the cluster (or your own build)

### Enable kubelet checkpointing

Add the following to each node's kubelet configuration (`/etc/kubernetes/kubelet-config.yaml` or equivalent):

```yaml
featureGates:
  ContainerCheckpoint: true
```

Then restart the kubelet:

```bash
systemctl restart kubelet
```

## Configuration

All settings are controlled via environment variables in [daemonset.yaml](daemonset.yaml). The MinIO credentials are stored in the `checkpoint-agent-credentials` Secret defined in [daemonset.yaml](daemonset.yaml).

| Variable | Default | Description |
|---|---|---|
| `CHECKPOINT_DIR` | `/var/lib/kubelet/checkpoints` | Host path watched for checkpoint archives |
| `MINIO_ENDPOINT` | `54.255.162.223:32000` | MinIO endpoint (`host:port`, no scheme) |
| `MINIO_ACCESS_KEY` | — | MinIO access key (read from Secret) |
| `MINIO_SECRET_KEY` | — | MinIO secret key (read from Secret) |
| `MINIO_BUCKET` | `checkpoints` | MinIO bucket name (created automatically if absent) |
| `PULL_INTERVAL` | `1m` | How often to pull missing files from MinIO (Go duration string, e.g. `30s`, `5m`) |
| `CONTROLLER_URL` | `http://54.255.162.223:30092/heartbeat` | Heartbeat POST endpoint on the management cluster |
| `AWS_REGION` | _(empty)_ | Set to your AWS region (e.g. `ap-southeast-1`) if nodes use `.compute.internal` hostnames |

### Update credentials before deploying

Edit the `checkpoint-agent-credentials` Secret in [daemonset.yaml](daemonset.yaml) and replace the placeholder values:

```yaml
stringData:
  MINIO_ACCESS_KEY: <your-access-key>
  MINIO_SECRET_KEY: <your-secret-key>
```

### Update endpoints before deploying

In the same file, set `MINIO_ENDPOINT` and `CONTROLLER_URL` to match your environment:

```yaml
- name: MINIO_ENDPOINT
  value: "<minio-host>:<port>"
- name: CONTROLLER_URL
  value: "http://<controller-host>:<port>/heartbeat"
```

## RBAC

The package creates two service accounts:

| ServiceAccount | Scope | Purpose |
|---|---|---|
| `checkpoint-agent` | ClusterRole | Read `nodes` — used by the agent to fetch node annotations and addresses |
| `checkpoint-sa` | Role + ClusterRole | `pods/checkpoint`, `nodes/checkpoint`, `nodes/proxy` — used by external callers that trigger kubelet checkpoints via the API |

## Deployment

### Fetch the package

```bash
kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] checkpoint-agent
```

Details: https://kpt.dev/reference/cli/pkg/get/

### View package content

```bash
kpt pkg tree checkpoint-agent
```

Details: https://kpt.dev/reference/cli/pkg/tree/

### Customize and apply

1. Edit credentials and endpoints as described in [Configuration](#configuration).
2. Initialize and apply:

```bash
kpt live init checkpoint-agent
kpt live apply checkpoint-agent --reconcile-timeout=2m --output=table
```

Details: https://kpt.dev/reference/cli/live/

### Verify the agent is running

```bash
kubectl -n checkpoint-agent get daemonset checkpoint-agent
kubectl -n checkpoint-agent get pods -o wide
kubectl -n checkpoint-agent logs -l app=checkpoint-agent -f
```

Expected log output once running:

```
Checkpoint agent with checksum validation running...
Heartbeat client started for node: ip-10-0-1-5.ap-southeast-1.compute.internal (10.0.1.5)
heartbeat sent: node=ip-10-0-1-5... ip=10.0.1.5 cluster=my-cluster
```

## Triggering a checkpoint manually

With `checkpoint-sa` permissions, checkpoint a running container via the kubelet API:

```bash
# Get a token for checkpoint-sa
TOKEN=$(kubectl -n checkpoint-agent create token checkpoint-sa)

# Trigger a checkpoint (replace variables as appropriate)
kubectl proxy &
curl -X POST \
  "http://127.0.0.1:8001/api/v1/nodes/<node-name>/proxy/checkpoint/<namespace>/<pod-name>/<container-name>" \
  -H "Authorization: Bearer $TOKEN"
```

The kubelet writes the archive to `CHECKPOINT_DIR` and the agent uploads it to MinIO automatically.

## Security context

The agent runs as **root** (`runAsUser: 0`) with `allowPrivilegeEscalation: false` and `readOnlyRootFilesystem: false`. Root is required to read files written by the kubelet under `/var/lib/kubelet/checkpoints`. It does **not** run in privileged mode.

## Scheduling

The DaemonSet targets **worker nodes only** via a node affinity rule that excludes nodes with the `node-role.kubernetes.io/control-plane` label. Tolerations are present so it can still be scheduled if taints exist on master/control-plane nodes when needed.

## Uninstall

```bash
kpt live destroy checkpoint-agent
```
