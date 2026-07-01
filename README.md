# hermes-runtime

Hermes Agent profile을 [agents-runtime](https://github.com/yoosungung/agent-runtime) **General tier**와 같은 방식으로 운영하는 pool 런타임.

- **Profile 정본**: Postgres **VFS** (`/profile/…`) — [docs/vfs-profile-design.md](docs/vfs-profile-design.md)
- **세션**: Hermes SessionDB Postgres
- **Invoke**: VFS pull → emptyDir scratch → AIAgent → VFS push

| 문서 | 내용 |
|------|------|
| [docs/vfs-profile-design.md](docs/vfs-profile-design.md) | **VFS 확정 설계** |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 계약 |
| [ROADMAP.md](ROADMAP.md) | 단계별 일정 |
| [runtimes/hermes-base/DESIGN.md](runtimes/hermes-base/DESIGN.md) | pool 내부 설계 |
| [deploy/DESIGN.md](deploy/DESIGN.md) | k8s |
| [docs/agents-runtime-integration.md](docs/agents-runtime-integration.md) | monorepo 통합 체크리스트 |

## Quickstart (개발)

```bash
uv sync --all-packages
uv run pytest runtimes/hermes-base/tests -q
```

`runtime-common`은 로컬 `../../works/agents-runtime/packages/common` path dependency (없으면 stub).

## Status

P0 — 설계·스켈레톤. [ROADMAP.md](ROADMAP.md) 참조.
