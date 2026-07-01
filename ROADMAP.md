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
- [ ] SPA Hermes agent 등록 UI
- [ ] ext-authz pool routing
- [ ] build-images CI
- [ ] 멀티 pod E2E

## P3 — hardening

- [ ] SSE streaming
- [ ] UserVfs per-user memory (optional)
- [ ] Opik trace
- [ ] push 충돌 감지·감사 로그

## P4 — (선택) Gateway

- Chat UI only 유지 또는 별도 gateway 설계
