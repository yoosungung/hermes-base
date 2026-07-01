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

## Commands

```bash
IMAGE_TAG=$(git rev-parse HEAD) make k8s-apply-dev   # agents-runtime
kubectl -n runtime rollout restart deployment/agent-pool-hermes
```

## 제거된 항목

- `hermes-profiles` PVC
- `HERMES_PROFILES_ROOT` volumeMount
