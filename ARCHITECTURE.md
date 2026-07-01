# ARCHITECTURE.md

Hermes Profile General tier를 agents-runtime에 통합하기 위한 **hermes-runtime** 저장소의 불변 계약.

`agents-runtime`의 `deploy_mode='general'`(DeepAgents + 페르소나 + MCP)과 **대칭 UX**로, Hermes profile을 번들 없이 등록·lazy 활성화한다.

**Profile 저장 (확정)**: 정본은 **agents-runtime Postgres VFS** (`vfs_agent_files`). pod 로컬은 invoke scratch만. 상세: [docs/vfs-profile-design.md](docs/vfs-profile-design.md).

---

## 1. 계약사항 (불변 규칙)

### agents-runtime과의 정합

| 항목 | general tier | hermes-runtime tier |
|------|--------------|---------------------|
| `deploy_mode` | `general` | `hermes_general` |
| `runtime_pool` | `agent:compiled_graph` | `agent:hermes` |
| 번들 | 없음 | 없음 |
| `entrypoint` / `bundle_uri` | `NULL` | `NULL` |
| `checksum` | `NULL` (캐시 키: `general:{name}:{version}`) | `NULL` (캐시 키: `hermes:{name}:{version}`) |
| 등록 API | `POST /api/source-meta/general` | `POST /api/source-meta/hermes-general` |
| Pool 이미지 | `agent-base` | `hermes-base` |
| Pool env | `RUNTIME_KIND=compiled_graph` | `RUNTIME_KIND=hermes` |
| Profile·메모리·skills 정본 | VFS `/agent/…` (DeepAgents backend) | VFS `/profile/…` under `agent/{name}` |

### Profile = 논리 agent

- `source_meta.name` = Hermes **profile 이름** (`my-special-hermes`).
- 등록 시 `source_meta` INSERT + **VFS seed** (`/profile/SOUL.md`, `config.yaml`, skills).
- 첫 `/invoke`: VFS **pull** → scratch `HERMES_HOME` → `AIAgent` build(warm) → **push** (runtime 변경분).

### Pod 외부 상태 (멀티 pod)

| 데이터 | 저장소 | 비고 |
|--------|--------|------|
| Profile 트리 (SOUL, config, skills, memories 파일) | **VFS Postgres** `vfs_agent_files` | `kind=agent`, `agent_name=name`, path `/profile/…` |
| 사용자 프로필 (`USER.md`) | **VFS Postgres** `vfs_user_files` | `user_id`, path `/hermes/{agent_name}/memories/USER.md` |
| 세션·메시지 | **Postgres** Hermes SessionDB (`HERMES_SESSION_DSN`) | `sessions.state_backend=postgres` |
| 동시성 | **Redis** profile lock `rt:lock:hermes:profile:{name}` | invoke 단위 |
| Invoke scratch | pod **emptyDir** `HERMES_WORK_DIR` | persist 금지 |
| `AIAgent` 인스턴스 | pod 메모리 (`InstanceCache`) | pod 이동 시 rebuild |

**RWX PVC 사용하지 않음.**

### `/invoke` 계약

`agent-base`와 동일 payload·헤더:

- Body: `{agent, version?, input, session_id?, principal?, stream?}`
- Headers: `x-principal`, `x-runtime-cfg`, `x-runtime-secrets-ref`, `Authorization`
- `session_id` = agents-runtime `chat_threads.provider_session_id`

`deploy_mode == 'hermes_general'` 분기:

1. `resolve` → `source` + `user`
2. Redis **profile lock** 획득
3. `ProfileVfsSync.pull` → scratch 디렉터리
4. (필요 시) `seed_from_config` — 등록 config가 VFS보다 새일 때
5. `profile_runtime_scope(scratch)` → `HERMES_HOME`
6. `get_or_build_hermes_agent` → `AIAgent`
7. `run_conversation(user_message, task_id=session_id)`
8. `ProfileVfsSync.push` — `memories/**`(USER.md 제외), `skills/**` 등 변경분
8b. `UserProfileVfsSync.push` — `memories/USER.md` → user VFS
9. lock 해제

### MCP

agents-runtime MCP는 Envoy `/v1/mcp/invoke-internal`. **MCP Bridge toolset** (`runtime_mcp`)이 JWT forward.

### 이것만은 하지 말 것

- profile마다 별도 OCI 이미지·Deployment 만들지 말 것.
- profile 정본을 pod 로컬·RWX PVC에만 두지 말 것.
- invoke 후 **push 없이** scratch 폐기하지 말 것 (메모리·skill 유실).
- Hermes core를 VFS-native로 포크하지 말 것 — **pull/push adapter**만.

---

## 2. 컴포넌트 개요

```
tests/hermes/
├── vendor/hermes-agent/
├── runtimes/hermes-base/       # ProfileVfsSync, /invoke
├── docs/vfs-profile-design.md  # VFS 확정 설계
└── deploy/

agents-runtime/ (통합)
├── runtimes/hermes-base/
├── packages/common/            # vfs store 재사용
├── backend/                    # hermes-general 등록 + VFS seed
└── deploy/k8s/base/agent-pool-hermes.yaml  # VFS_DSN, emptyDir only
```

### 데이터 흐름

```
[Chat UI] → Envoy /v1/agents/invoke → ext-authz (agent:hermes → agent-pool-hermes)
    → hermes-base /invoke
    → Redis lock
    → VFS pull (Postgres) → emptyDir scratch
    → AIAgent.run_conversation
    → VFS push (memories, skills, …)
    → SessionDB (Postgres, session_id)
    → MCP Bridge → Envoy
```

---

## 3. source_meta.config.hermes 스키마

등록 폼·resolve 헤더용. **런타임 정본은 VFS** — 등록/PATCH 시 VFS와 동기화.

```json
{
  "hermes": {
    "soul": "당신은 …",
    "model": "anthropic/claude-sonnet-4-6",
    "mcp_servers": ["search-server"],
    "mcp_tools": [{"server": "search-server", "name": "naver_search", "description": "..."}],
    "enabled_toolsets": ["web", "runtime_mcp"],
    "skills": ["plan"],
    "memory": {"enabled": true},
    "max_iterations": 90
  }
}
```

---

## 4. hermes-agent 벤더링

- `git+https://github.com/NousResearch/hermes-agent.git` (main, CI SHA pin)
- 패치: `vendor/hermes-agent/patches/` — profile scope, Postgres session
- [vendor/hermes-agent/DESIGN.md](vendor/hermes-agent/DESIGN.md)

---

## 5. agents-runtime 통합

[docs/agents-runtime-integration.md](docs/agents-runtime-integration.md)
