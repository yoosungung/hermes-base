# deploy

K8s 배포 — **VFS + emptyDir**, profile PVC 없음.

## agent-pool-hermes (agents-runtime)

`deploy/k8s/agent-pool-hermes.yaml.example` 참고.

### 필수 env

| env | source |
|-----|--------|
| `RUNTIME_KIND=hermes` | literal |
| `VFS_DSN` | secret `postgres-credentials` / `VFS_DSN` (general pool과 동일) |
| `HERMES_SESSION_DSN` | 동일 Postgres DSN |
| `HERMES_WORK_DIR=/var/cache/hermes-work` | literal |
| `REDIS_URL` | `runtime-env` ConfigMap |
| `MCP_GATEWAY_URL` | Envoy internal |

### volumes

```yaml
volumeMounts:
  - name: hermes-work
    mountPath: /var/cache/hermes-work
volumes:
  - name: hermes-work
    emptyDir: {}
```

**PVC / RWX 없음.** VFS는 Postgres, 세션은 Postgres, scratch만 pod 로컬.

### replicas

- dev: `1` 가능
- prod: `2+` — VFS + SessionDB + Redis lock으로 pod 간 일관성

## ext-authz

`POOL_HERMES_URL=http://agent-pool-hermes.runtime.svc.cluster.local:8080`

## NetworkPolicy

`runtime/role: pool` — 기존과 동일.

## OCI runtime-slim

hermes 단독 repo에서 이미지 빌드:

```bash
# runtime-common 스테이징 (agents-runtime path dep)
./scripts/stage-docker-build.sh

docker build \
  --build-arg GIT_SHA="$(git rev-parse HEAD)" \
  --build-arg HERMES_REVISION="$(cat vendor/hermes-agent/REVISION 2>/dev/null || echo dev)" \
  -f runtimes/hermes-base/Dockerfile \
  -t hermes-base:local .

./scripts/check-hermes-image-size.sh hermes-base:local
./scripts/stage-docker-build.sh --clean
```

CI: `.github/workflows/hermes-oci.yml` — install policy grep + docker build + max-size gate (1200 MiB).

agents-runtime monorepo 통합 시 동일 Dockerfile을 `runtimes/hermes-base/`에서 재사용 (`packages/common` in-tree).

## Commands

```bash
IMAGE_TAG=$(git rev-parse HEAD) make k8s-apply-dev   # agents-runtime
kubectl -n runtime rollout restart deployment/agent-pool-hermes
```

## 제거된 항목

- `hermes-profiles` PVC
- `HERMES_PROFILES_ROOT` volumeMount
