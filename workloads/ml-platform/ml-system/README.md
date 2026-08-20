# Kubernetes Deployment — Frontend + quota-api

Production-ready manifests for the two application components: the Next.js
frontend and the quota-api (FastAPI) backend. Everything else this platform
depends on (JupyterHub, Enterprise Gateway, Keycloak, monitoring stack) is
deployed separately — see `k8s/jhub-values.yaml`, `docs/jhub_eg_keycloak/`,
and `k8s/monitoring/`.

Files are numbered in the order they should be applied — `kubectl apply -f`
against a whole directory applies files in filename order, so `kubectl apply
-f deploy/k8s/` just works.

## What's here

| File | Kind | Purpose |
|---|---|---|
| `00-namespace.yaml` | Namespace | `jhub-ns` — idempotent, skip if it already exists |
| `01-secrets.example.yaml` | Secret (×2) | **Template only — see below** |
| `02-configmap-quota-api.yaml` | ConfigMap (×2) | Non-secret backend config + UI-tuning config |
| `03-configmap-frontend.yaml` | ConfigMap | Non-secret frontend runtime config (browser-facing URLs) |
| `04-rbac-quota-api.yaml` | ServiceAccount, ClusterRole(Binding), Role(Binding) | Permissions quota-api needs to manage nodes/pods/PVCs/node-provisioning |
| `05-pvc-quota-api.yaml` | PersistentVolumeClaim | SQLite database storage |
| `06-deployment-quota-api.yaml` | Deployment | Backend API |
| `07-service-quota-api.yaml` | Service | Backend API (NodePort 30082) |
| `08-deployment-frontend.yaml` | Deployment | Frontend UI |
| `09-service-frontend.yaml` | Service | Frontend UI (NodePort 30083) |
| `10-ingress.yaml` | Ingress | Optional — alternative to the NodePort Services |

Model saving + vLLM serving needs no manifest of its own: quota-api creates a per-user artifact PVC automatically on that user's first save (see `MODEL_ARTIFACT_STORAGE_CLASS` below) — nothing to `kubectl apply`.

## Required Secrets

Two Secrets, described in `01-secrets.example.yaml` (do not apply that file
directly — copy it or create the Secrets imperatively):

1. **`quota-api-secrets`** — `keycloak-admin-password`, `jupyterhub-api-token`,
   `quota-api-token` (all required), `credential-key` (optional — see the
   comment in the template for why), `harbor-secret`/`harbor-admin-password`
   (optional — only needed if you enable the Harbor auto-seed/robot-bootstrap
   feature via the commented `HARBOR_*` keys in
   `02-configmap-quota-api.yaml`).
2. **`ghcr-pull-secret`** — only needed if your GHCR (or other Git registry)
   images are private. GHCR packages are **private by default on first
   push** (see `.github/workflows/docker-frontend.yml`) — either flip the
   package to public in GitHub's package settings, or create this secret
   with a real personal access token:
   ```bash
   kubectl create secret docker-registry ghcr-pull-secret \
     --docker-server=ghcr.io \
     --docker-username=<your-github-username> \
     --docker-password=<personal-access-token> \
     --namespace=jhub-ns
   ```
   If your images are public, delete `ghcr-pull-secret` and remove the
   `imagePullSecrets:` block from both Deployments.

## Required ConfigMaps

Both are plain YAML in this directory, edited directly (no secrets in
either — safe to commit your own environment's copy):

- **`quota-api-config`** — internal cluster DNS URLs, namespaces, GPU VRAM
  size, monitoring endpoints. See the comments in
  `02-configmap-quota-api.yaml` for which values are cluster-internal vs.
  need to be your public IP/hostname. If you're using the save-model +
  vLLM-serving feature, `MODEL_ARTIFACT_STORAGE_CLASS` must be set to a
  real RWX-capable StorageClass in your cluster — everything else in that
  section has a working default.
- **`quota-api-ui-config`** — optional frontend UI tuning
  (`frontend/lib/uiConfig.ts` schema), deep-merged onto compiled defaults.
  Safe to leave as-is.
- **`frontend-config`** — browser-facing URLs (quota-api, Keycloak). These
  MUST be reachable from a user's own machine, not cluster-internal DNS.
  Also carries the optional `NEXT_PUBLIC_ADMIN_EXTERNAL_MONITORING` — set it
  to show an "Advanced Monitoring" button in the admin Monitoring section;
  omit it (the default) to hide the button entirely.

Every `CHANGE-ME` placeholder in `02-configmap-quota-api.yaml`,
`03-configmap-frontend.yaml`, and `10-ingress.yaml` needs a real value
before applying.

## Deployment order

```bash
# 1. Namespace (skip if it already exists)
kubectl apply -f deploy/k8s/00-namespace.yaml

# 2. Secrets — copy the template first, do NOT commit real secrets
cp deploy/k8s/01-secrets.example.yaml deploy/k8s/01-secrets.yaml
# edit deploy/k8s/01-secrets.yaml with real values, then:
kubectl apply -f deploy/k8s/01-secrets.yaml

# 3. Everything else
kubectl apply -f deploy/k8s/02-configmap-quota-api.yaml
kubectl apply -f deploy/k8s/03-configmap-frontend.yaml
kubectl apply -f deploy/k8s/04-rbac-quota-api.yaml
kubectl apply -f deploy/k8s/05-pvc-quota-api.yaml
kubectl apply -f deploy/k8s/06-deployment-quota-api.yaml
kubectl apply -f deploy/k8s/07-service-quota-api.yaml
kubectl apply -f deploy/k8s/08-deployment-frontend.yaml
kubectl apply -f deploy/k8s/09-service-frontend.yaml

# Optional — only if you're using an Ingress controller
kubectl apply -f deploy/k8s/10-ingress.yaml
```

Or, once `01-secrets.yaml` exists locally (it's gitignored — see below),
apply everything in one shot since the files are numbered in dependency
order:

```bash
kubectl apply -f deploy/k8s/
```

### Verify

```bash
kubectl get pods -n jhub-ns -l 'app in (quota-api,frontend)'
kubectl logs -n jhub-ns deploy/quota-api --tail=20
kubectl logs -n jhub-ns deploy/frontend --tail=20

kubectl port-forward svc/quota-api 9000:8000 -n jhub-ns &
curl http://localhost:9000/health
```

## Updating the image / rolling out a new version

Images are built by CI and pushed to GHCR (see
`.github/workflows/docker-frontend.yml` for the frontend; quota-api follows
the same pattern). To roll out a new build:

```bash
# Frontend
kubectl set image deployment/frontend frontend=ghcr.io/vitu-mafeni/ml-platform-frontend:<new-tag> -n jhub-ns
kubectl rollout status deployment/frontend -n jhub-ns

# quota-api
kubectl set image deployment/quota-api quota-api=ghcr.io/vitu-mafeni/quota-api:<new-tag> -n jhub-ns
kubectl rollout status deployment/quota-api -n jhub-ns

# Rollback either one if something's wrong
kubectl rollout undo deployment/<frontend|quota-api> -n jhub-ns
```

Or edit the `image:` line directly in `06-deployment-quota-api.yaml` /
`08-deployment-frontend.yaml` and re-apply — either approach triggers the
same RollingUpdate. **Use immutable tags (not `latest`) for anything you
intend to roll back to reliably** — `latest` can silently change under you
the next time a pod restarts for any reason.

## Notes on production-readiness choices

- **quota-api is pinned to `replicas: 1`** — it persists state in a local
  SQLite file on a `ReadWriteOnce` PVC (`05-pvc-quota-api.yaml`). SQLite does
  not support safe concurrent multi-writer access from separate pods.
  Scaling quota-api horizontally requires migrating to a server-backed
  database (Postgres/MySQL) first — not covered by these manifests.
- **`maxUnavailable: 0` on quota-api's rolling update** — for the same
  reason: the old pod must fully release the SQLite file before the new one
  mounts the PVC.
- **The frontend has no dedicated health endpoint**, so both probes hit `/`
  — this is a login/portal page and always returns 200 once the Next.js
  server is up, regardless of auth state.
- **`imagePullSecrets` is included by default** since GHCR packages start
  private — remove it once (or if) your packages are public.

## kpt package / PackageVariant

This directory is also a [kpt](https://kpt.dev) package (`Kptfile` +
`# kpt-set:` comments on every overridable value) so a Porch `PackageVariant`
can use it as an upstream template and render one downstream variant per
target cluster/environment, substituting that cluster's IPs/hostnames/
namespaces/image tags without hand-editing every numbered file — with the
override values living directly, inline, in the `PackageVariant`'s own
`spec`, no separate object to pre-create.

- **`Kptfile`** — declares the package and its single-step pipeline:
  `apply-setters`, configured with an empty `configMap: {}` by default (a
  safe no-op — see below).
- **Every overridable value, across `02-configmap-quota-api.yaml`,
  `03-configmap-frontend.yaml`, `04-rbac-quota-api.yaml`,
  `06-deployment-quota-api.yaml`, `08-deployment-frontend.yaml`, and
  `10-ingress.yaml`**, carries a `# kpt-set: ${NAME}` comment right next to
  its committed default value
  (e.g. `GRAFANA_URL: "http://192.168.3.234:32300" # kpt-set: ${GRAFANA_URL}`).
  Some names appear on more than one line by design — `EG_NAMESPACE` also
  tags the two `namespace: enterprise-gateway` RBAC objects in
  `04-rbac-quota-api.yaml`, and `KERNELSPECS_PVC_PATH` also tags the
  Deployment's matching `volumeMounts[].mountPath`, so overriding either
  value updates every place that has to agree with it, not just the env var.
  `apply-setters` finds every such comment across the whole package and
  replaces the value in front of it with whatever's supplied for that setter
  name — wherever it appears, in whichever file. Setter names match the env
  var / config key names 1:1 for direct traceability.

Since a setter only changes something when its name is actually supplied,
`kpt fn render deploy/k8s` with the Kptfile's committed empty `configMap: {}`
is a safe no-op — every value stays exactly what's written. Making a new
value settable is a one-line change: add `# kpt-set: ${NAME}` next to it, no
other file needs to change.

### Test locally (no Porch/cluster needed)

```bash
kpt fn render deploy/k8s
```

### Why not Starlark/ApplyReplacements (both tried first)

Two earlier designs in this package's history didn't survive contact with a
real render — both replaced here by `apply-setters`, kept for the record:

1. **A custom `StarlarkRun` + `ApplyReplacements` sourcing from a separate
   injected `ConfigMap`** (`spec.injectors`) — worked, but injection only
   supports wholesale replacement of a `ConfigMap`'s entire `data` (confirmed
   in `kptdev/porch`'s `injection.go`), requires a second real object
   pre-created in the `PackageVariant`'s own namespace, and the controller
   doesn't watch that object for changes (`packagevariant_controller.go`'s
   `SetupWithManager` only watches `PackageVariant` and `PackageRevision`) —
   so a value change needed a manual "touch the PackageVariant to force a
   resync" step.
2. **The same `ApplyReplacements`, sourcing from `spec.packageContext.data`**
   (merged into the standard `ConfigMap/kptfile.kpt.dev`) — genuinely inline
   in the `PackageVariant`, no second object. But `kpt`'s own built-in
   `PackageContextGenerator` (`pkg/lib/builtins/pkg_context.go`) drops and
   regenerates `ConfigMap/kptfile.kpt.dev` on **every** render, keeping only
   `data.name` — any custom key placed there, whether by us or by
   `packageContext.data`, is wiped before the package's own pipeline ever
   runs. Confirmed by an actual render failure: `fieldPath data.KEYCLOAK_BASE_URL
   is missing for replacement source ConfigMap.../kptfile.kpt.dev`.

`apply-setters` sidesteps both problems: its functionConfig is a plain
`ConfigMap` (so `PackageVariant.spec.pipeline.mutators[].configMap` can
supply it inline, no separate object), and it doesn't touch
`ConfigMap/kptfile.kpt.dev` at all, so kpt's built-in generator can't
interfere with it.

### PackageVariant example

Verified against `kptdev/porch`'s actual Go source:

- `apiVersion: config.porch.kpt.dev/v1alpha1` for `PackageVariant`
  (`api/porchconfig/v1alpha1/packagevariant_types.go`).
- `spec.upstream.revision` is the upstream package's **numeric Porch revision**
  (`int`), not a git ref/tag.
- `Function.ConfigMap map[string]string` (`kptdev/kpt`'s
  `api/kptfile/v1/types.go`) is the inline shorthand: a mutator entry with
  `configMap: {...}` builds a plain `ConfigMap` functionConfig on the fly —
  exactly what `apply-setters` expects, so the setter values can be literal
  key/value pairs directly in the `PackageVariant`'s own `spec`.
- A `PackageVariant`'s own `spec.pipeline.mutators` are **prepended** to this
  package's upstream pipeline (confirmed in `ensureKRMFunctions` — new
  functions run first, then whatever the `Kptfile` already had), so this
  mutator's real setter values apply first; the Kptfile's own trailing
  `apply-setters` step (empty `configMap: {}`) then runs harmlessly — with no
  setter values to supply, it changes nothing, so it never undoes what the
  PackageVariant's step just set.

```yaml
apiVersion: config.porch.kpt.dev/v1alpha1
kind: PackageVariant
metadata:
  name: ml-platform-deploy
spec:
  upstream:
    repo: ui-ml-platform        # Repository object pointing at this repo
    package: deploy/k8s
    revision: 1                 # numeric Porch revision of the upstream package
  downstream:
    repo: ml-cluster-deploy     # target Porch/Git repo for rendered packages
    package: ml-platform-deploy
  pipeline:
    mutators:
      - image: ghcr.io/kptdev/krm-functions-catalog/apply-setters:v0.2.4
        configMap:
          # Only list setters this cluster needs different from the
          # committed default next to each `# kpt-set:` comment — every
          # setter omitted here leaves that default untouched. Shown below:
          # this cluster's actual current values (redundant with the
          # committed defaults right now — meaningful once a second/
          # different target exists, or a value changes).
          GRAFANA_URL: "http://192.168.3.234:32300"
          CHECKPOINT_API_URL: "http://192.168.3.234:30829"
          QUOTA_RESTORE_ALLOW_RESIZE: "false"
          MODEL_ARTIFACT_STORAGE_CLASS: "nfs-csi"
          HARBOR_BASE_URL: "http://10.9.0.13:30728"
          HARBOR_VERIFY_TLS: "false"
          HARBOR_ADMIN_USERNAME: "admin"
          HARBOR_COPY_TIMEOUT_SECONDS: "10800"
          NEXT_PUBLIC_QUOTA_API: "http://192.168.3.234:30082"
          NEXT_PUBLIC_KC_URL: "http://192.168.3.234:30090"
          EG_KERNELSPECS_NFS_SERVER: "192.168.3.234"
```

That's the whole thing — one object, no companion `ConfigMap` to pre-create
anywhere. `KEYCLOAK_BASE_URL`, `JUPYTERHUB_API_URL`, `EG_NAMESPACE`,
`KERNELSPECS_PVC_PATH`, `KERNEL_SYNC_TIMEOUT_SECONDS`, `QUOTA_API_IMAGE`,
`FRONTEND_IMAGE`, `PORTAL_HOST`, `API_HOST` are omitted above because they
already match the committed default for this cluster — add any of them to
`configMap` the moment they need to differ.

Credentials (`HARBOR_ADMIN_PASSWORD`, `KEYCLOAK_ADMIN_PASSWORD`,
`JUPYTERHUB_API_TOKEN`, `QUOTA_API_TOKEN`) never belong in this `configMap` —
it ends up as plain-text data inside the rendered package's `apply-setters`
functionConfig. They stay on the existing `01-secrets.example.yaml` /
`kubectl create secret` path, entirely independent of this `PackageVariant`.

**If the values change later:** edit `spec.pipeline.mutators[].configMap` on
this same `PackageVariant` object and re-apply — the controller watches the
`PackageVariant` object directly (`For(&configapi.PackageVariant{})` in
`SetupWithManager`), so a direct edit is picked up on its own; no manual
"force resync" step needed.

The exact Repository objects (`ui-ml-platform`, `ml-cluster-deploy` above)
and how upstream/downstream repos are registered with Porch depend on your
cluster's setup (this project's uses a separate `nephio/ml-cluster.git` repo
for GitOps, not this one) — confirm those names against your own Porch
objects before applying.

## Not covered here

This directory only covers the frontend and quota-api. It does NOT deploy:
JupyterHub/Enterprise Gateway/Keycloak (`k8s/jhub-values.yaml`,
`docs/jhub_eg_keycloak/`), the monitoring stack (`k8s/monitoring/`), the
`eg-templates` kernelspecs image, or the `jupyterlab-missed-output-replay`
extension delivery pipeline.
