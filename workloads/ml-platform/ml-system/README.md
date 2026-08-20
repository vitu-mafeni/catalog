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
`package-context.yaml` + `apply-replacements.yaml` + `starlark-run.yaml`) so a
Porch `PackageVariant` can use it as an upstream template and render one
downstream variant per target cluster/environment, substituting that
cluster's IPs/hostnames/namespaces/image tags without hand-editing every
numbered file — with the override values living directly, inline, in the
`PackageVariant`'s own `spec`, no separate object to pre-create.

- **`Kptfile`** — declares the package and its two-step pipeline:
  `apply-replacements` runs first, then `starlark`.
- **`package-context.yaml`** — the standard kpt "package context" file: a
  well-known `ConfigMap` named `kptfile.kpt.dev` that kpt tooling normally
  auto-populates with just the package's own name (`data.name`). This package
  also uses it to carry the committed DEFAULT values for everything a
  `PackageVariant` can override — a `PackageVariant`'s `spec.packageContext.data`
  **merges** directly into this exact ConfigMap's `data` (confirmed in
  `kptdev/porch`'s `ensurePackageContext`, which runs *before* the pipeline
  executes) — so overriding one key never disturbs the rest.
- **`apply-replacements.yaml`** — an `ApplyReplacements` functionConfig, one
  `source`/`targets` entry per key, propagating each
  `ConfigMap/kptfile.kpt.dev` → `data.<KEY>` field into `starlark-run.yaml`'s
  `StarlarkRun` → `params.<KEY>`.
- **`starlark-run.yaml`** — a `StarlarkRun` functionConfig (`source` and
  `params` are TOP-LEVEL fields — there is no `spec:` wrapper). `source` is a
  GENERIC substitution script: for every `ConfigMap` in the package, any
  `data` key matching a `params` name gets that key's value replaced (plus
  two special cases: `Deployment` image tags via `QUOTA_API_IMAGE`/
  `FRONTEND_IMAGE`, and `Ingress` hosts via `PORTAL_HOST`/`API_HOST`).
  `Secret` resources are never touched — real credentials stay out of this
  GitOps package entirely (see "Required Secrets" above).

Since the `starlark` script only replaces a key when it's present in
`params`, ANY ConfigMap data key already in this package is overridable just
by adding that exact key to all three files (`package-context.yaml`,
`apply-replacements.yaml`, `starlark-run.yaml`'s `params`) — no script
changes needed, as long as it's a real (uncommented) YAML key already in the
target ConfigMap.

### Test locally (no Porch/cluster needed)

```bash
kpt fn render deploy/k8s
```

Re-runs the pipeline in place using the checked-in defaults — idempotent,
safe to run repeatedly, and a good way to confirm the package still renders
before wiring up a real PackageVariant.

### PackageVariant example

Verified against `kptdev/porch`'s actual Go source — not guessed:

- `apiVersion: config.porch.kpt.dev/v1alpha1` for `PackageVariant`
  (`api/porchconfig/v1alpha1/packagevariant_types.go`).
- `spec.upstream.revision` is the upstream package's **numeric Porch revision**
  (`int`), not a git ref/tag.
- `spec.packageContext.data` (a plain `map[string]string`) is copied — via
  `maps.Copy(data, pv.Spec.PackageContext.Data)` in
  `ensurePackageContext` — into the EXISTING `data` of
  `ConfigMap/kptfile.kpt.dev` (found by `getFileKubeObject(prr,
  "package-context.yaml", "ConfigMap", "kptfile.kpt.dev")`). That's a real
  merge, not a wholesale replace — a `PackageVariant` only needs to list the
  keys it's actually changing; everything else keeps `package-context.yaml`'s
  committed default. (`spec.packageContext.removeKeys` is also available, to
  delete a key entirely rather than override it.)
- Execution order in the controller's `Reconcile` (confirmed directly):
  `ensurePackageContext` → `ensureKRMFunctions` → `ensureConfigInjection` —
  so by the time the package's own pipeline (`apply-replacements` → `starlark`)
  actually runs, `kptfile.kpt.dev`'s `data` already reflects any
  `packageContext.data` override.
- This is genuinely simpler than the native `spec.injectors` mechanism (which
  we tried first): injectors only support wholesale replacement of a
  `ConfigMap`'s *entire* `data` field or a resource's *entire* `spec`
  (`injection.go`'s `allowedInjectionFields`), require a second, separately
  pre-created real object in the `PackageVariant`'s own namespace, and the
  controller doesn't even watch that object for changes. `packageContext.data`
  needs none of that — the values live directly in the `PackageVariant` you
  already have to author and apply.

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
  packageContext:
    data:
      # Only list keys this cluster needs different from
      # package-context.yaml's committed default — every key omitted here
      # keeps that default untouched. Shown below: this cluster's actual
      # current values (redundant with the committed defaults right now —
      # meaningful once a second/different target exists, or a value changes).
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
```

That's the whole thing — one object, no companion `ConfigMap` to pre-create
anywhere. `KEYCLOAK_BASE_URL`, `JUPYTERHUB_API_URL`, `EG_NAMESPACE`,
`KERNELSPECS_PVC_PATH`, `KERNEL_SYNC_TIMEOUT_SECONDS`, `QUOTA_API_IMAGE`,
`FRONTEND_IMAGE`, `PORTAL_HOST`, `API_HOST` are omitted above because they
already match `package-context.yaml`'s committed default for this cluster —
add any of them to `packageContext.data` the moment they need to differ.

Credentials (`HARBOR_ADMIN_PASSWORD`, `KEYCLOAK_ADMIN_PASSWORD`,
`JUPYTERHUB_API_TOKEN`, `QUOTA_API_TOKEN`) never belong in
`packageContext.data` — it ends up as plain-text `ConfigMap` data inside the
rendered package. They stay on the existing `01-secrets.example.yaml` /
`kubectl create secret` path, entirely independent of this `PackageVariant`.

Rendering then flows: `packageContext.data` merges into
`ConfigMap/kptfile.kpt.dev`'s `data` → `apply-replacements.yaml` copies each
`data.<KEY>` into `starlark-run.yaml`'s `params.<KEY>` → the `starlark`
mutator applies those params into `ml-backend-system-config`/
`frontend-config`'s matching keys, the two Deployments' image tags, and the
Ingress hosts.

**If the values change later:** edit `spec.packageContext.data` on this same
`PackageVariant` object and re-apply — that IS the object the controller
watches (`For(&configapi.PackageVariant{})` in `SetupWithManager`), so a
direct edit is picked up on its own; no extra "force resync" step needed
(unlike the injector approach this replaced, which needed one).

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
