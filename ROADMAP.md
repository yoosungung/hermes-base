# ROADMAP.md

## 저장 결정 (확정)

- Profile·장기 메모리·runtime skill 변경: **Postgres VFS** (`/profile/…`)
- 세션·메시지: **Hermes SessionDB Postgres**
- pod scratch: **emptyDir** — RWX PVC 없음
- 상세: [docs/vfs-profile-design.md](docs/vfs-profile-design.md)

## P0 — 설계·스캐폴딩

- [x] ARCHITECTURE + VFS 확정 설계
- [x] hermes-base 스켈레톤 (`ProfileMaterializer` — scratch용)
- [x] `ProfileVfsSync` + `MemoryAgentVfsStore` 테스트 (12건)
- [x] `profile_lock` Redis 테스트
- [x] `app.py` invoke: pull/lock/push wiring

## P1 — hermes-base MVP

- [x] MCP Bridge (`mcp_bridge.py` + JWT forward)
- [x] `/invoke` + 429 on lock contention
- [x] app 통합 테스트 (pull/run/push/lock)
- [x] `vendor-hermes.sh` (로컬 벤더링)
- [x] Postgres session E2E (wire-dev `HERMES_SESSION_DSN`)
- [x] VFS pull/push E2E with real asyncpg — `test_vfs_profile_wire.py` (`pytest -m integration`)

### P1 — OCI 이미지 슬림화 (`hermes-base` Dockerfile)

- [x] **Dockerfile multi-stage** + `prune-hermes-packages.sh`
- [x] **설치 후 prune** 스모크 테스트
- [x] **설계 문서** § Runtime-slim install 상세
- [x] **설치 정책** CI grep (`[gateway]`/`[all]` 금지)
- [ ] **(선택) 패치**: `hermes-agent[runtime]` optional-extra — upstream 기여 대기
- [x] **이미지 크기 검증** CI max-size gate (1200 MiB)

## P2 — agents-runtime 통합

- [x] workspace member 이식 (`runtimes/hermes-base`)
- [x] `POST /api/source-meta/hermes-general` + **VFS seed**
- [x] migration `0010_hermes_general.sql`
- [x] k8s `agent-pool-hermes.yaml` 예시
- [x] SPA Hermes agent 등록 UI
- [x] ext-authz pool routing
- [x] build-images CI
- [x] `PATCH /hermes-general/{id}` + SPA 편집
- [x] 멀티 pod E2E (`test_multipod_wire.py`)

## P3 — hardening

- [x] SSE streaming
- [x] UserVfs per-user memory (`USER.md` → `UserVfsStore` `/hermes/{agent}/…`)
- [x] Opik trace
- [x] push 충돌 감지·감사 로그

### P3 구현 메모

| 항목 | 설계 |
|------|------|
| SSE | `run_conversation(stream_callback=…)` → `data: {"text":…}\n\n` + `[DONE]` (`chatStream.ts` 호환). `None` delta 필터(tool call 중 premature close 방지) |
| Opik | `configure_opik` lifespan + `opik_trace_context` invoke/stream 경계 |
| push 충돌 | `PullManifest`에 pull 시점 `vfs_modified_at` 저장 → push 전 재조회 불일치 시 409 + structured audit log (`vfs_push_conflict`) |

## P4 — Gateway (확정: A)

- **Chat UI only** — agents-runtime SPA → Envoy `/v1/agents/invoke` → `hermes-base` 유일 진입점
- hermes-agent `gateway` / TUI / ACP adapter는 pool OCI에 포함하지 않음 (runtime-slim 유지)
- MCP는 agents-runtime Envoy + `mcp_bridge` JWT forward
