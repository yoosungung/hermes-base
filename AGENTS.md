# AGENTS.md

AI 코딩 어시스턴트용 작업 가이드. `CLAUDE.md`·`GEMINI.md`는 이 파일로의 심볼릭 링크 — **정본은 `AGENTS.md`**.

불변 규칙: [ARCHITECTURE.md](ARCHITECTURE.md). 일정: [ROADMAP.md](ROADMAP.md).

## 1. Documentation layout

| 파일 | 용도 | 위치 |
|------|------|------|
| `AGENTS.md` | 수행 방법 + 문서 레이아웃 | 루트 |
| `ARCHITECTURE.md` | 계약(불변) + 컴포넌트 간 인터페이스 | 루트 |
| `README.md` | 저장소 소개 + quickstart | 루트 |
| `ROADMAP.md` | 마일스톤 | 루트 |
| `runtimes/hermes-base/DESIGN.md` | hermes-base 내부 + Commands | `runtimes/hermes-base/` |
| `deploy/DESIGN.md` | k8s·통합 배포 | `deploy/` |
| `vendor/hermes-agent/DESIGN.md` | upstream 벤더링·패치 | `vendor/hermes-agent/` |
| `docs/vfs-profile-design.md` | **VFS profile 저장 (확정)** | `docs/` |
| `docs/agents-runtime-integration.md` | agents-runtime 변경 체크리스트 | `docs/` |

## 2. 수행 방법

- 설계·구현 전 문서 갱신: 계약 → `ARCHITECTURE.md`, 내부 → `*/DESIGN.md`, 일정 → `ROADMAP.md`.
- **TDD**: 스켈레톤 → 테스트 → 구현.
- Python 3.12, **uv** (`uv sync --all-packages`).
- `runtime-common`은 `../../works/agents-runtime/packages/common` path dep (로컬).
- hermes-agent는 `vendor/hermes-agent` + `scripts/vendor-hermes.sh` (main HEAD).

### Commands

```bash
uv sync --all-packages
uv run pytest runtimes/hermes-base/tests -q
uv run ruff check runtimes/hermes-base
./scripts/vendor-hermes.sh   # P1
bash scripts/check-hermes-install-policy.sh
./scripts/stage-docker-build.sh && docker build -f runtimes/hermes-base/Dockerfile .
```

## 3. Status

P1 — hermes-base MVP + wire-dev E2E + OCI runtime-slim 완료. P2 agents-runtime 통합 완료. P3 hardening(SSE·Opik·VFS conflict) 완료. UserVfs·P4 Gateway(A: Chat UI only) 확정.
