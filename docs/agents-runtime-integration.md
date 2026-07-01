# agents-runtime 통합 가이드

## VFS (확정)

Profile 정본: `AsyncpgAgentVfsStore`, `kind='agent'`, `agent_name=source_meta.name`, 경로 prefix `/profile/`.

상세: [vfs-profile-design.md](vfs-profile-design.md)

---

## 1. 저장소 이식

```text
tests/hermes/runtimes/hermes-base/  →  agents-runtime/runtimes/hermes-base/
tests/hermes/vendor/                →  agents-runtime/vendor/hermes-agent/
```

## 2. packages/common

- `AgentRuntimeKind.HERMES = "hermes"`
- `HermesGeneralSourceConfig` in `config_schema.py`
- `source_instance_key`: `hermes:{name}:{version}`
- (변경 없음) `AsyncpgAgentVfsStore` 재사용

## 3. backend

### `POST /api/source-meta/hermes-general`

1. `source_meta` INSERT
2. **VFS seed** (`vfs_agent_files`):

```python
await agent_vfs.write("agent", name, "/profile/SOUL.md", body.soul)
await agent_vfs.write("agent", name, "/profile/config.yaml", render_hermes_yaml(cfg))
for skill in body.skills:
    await agent_vfs.write("agent", name, f"/profile/skills/{skill}/SKILL.md", bundled_skill_content(skill))
```

3. Admin `/vfs/agents/agent/{name}` — general agent VFS UI 재사용 (경로 `/profile/…` 안내)

### `PATCH /api/source-meta/hermes-general/{id}`

- `soul` / `skills` 변경 → VFS upsert + `source_meta.config` 갱신

### migration

```sql
CHECK (deploy_mode IN ('bundle', 'image', 'general', 'hermes_general'));
```

## 4. runtimes/hermes-base

- `VFS_DSN` 필수, `create_asyncpg_pool` + `ProfileVfsSync`
- `HERMES_WORK_DIR` emptyDir
- `profile_lock` Redis

## 5. ext-authz / frontend / deploy

- `POOL_HERMES_URL`, `HermesAgentNewPage`, `agent-pool-hermes.yaml` (**PVC 제거**)
- `build-images.yml`: `hermes-base`

## 6. 검증 시나리오

1. 등록 → VFS에 `/profile/SOUL.md` 존재 (admin VFS UI)
2. Pod A invoke → memory 턴
3. Pod B invoke → VFS `memories/MEMORY.md` 반영·세션 연속
4. `skill_manage`로 skill 추가 → push → Pod B에서 `skills/` visible
5. 동시 invoke 동일 agent → 429 또는 lock 대기

## 7. wire-dev E2E (로컬 Mac → dev k8s)

`agents-runtime` 루트에서:

```bash
./scripts/wire-dev.sh up          # postgres:5432, redis:6379, envoy:8084
./scripts/wire-dev.sh env         # .env.dev.local (VFS_DSN, HERMES_SESSION_DSN, …)
uv sync --all-packages
uv run pytest runtimes/hermes-base/tests/test_vfs_profile_wire.py -m integration -v
```

- `VFS_DSN` / `HERMES_SESSION_DSN`: wire-dev가 쓰는 dev Postgres (`runtime` DB)
- 풀 로컬 디버그: `./scripts/wire-dev.sh pool-isolate hermes` → `:8095/invoke`
- 단위 테스트(mock VFS): `uv run pytest runtimes/hermes-base/tests -q -m "not integration"`
