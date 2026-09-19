# ai-setup — AI 코딩 에이전트 개인 설정 (Claude Code · Codex 공용)

어느 PC 에서든 이 레포 하나를 받아 `install` 을 한 번 돌리면, 그 PC 의 **모든 프로젝트**에서 **Claude Code 와 Codex 가 같은 스킬·같은 전역 규칙**을 쓴다. 프로젝트 레포에는 아무것도 넣지 않는다 — 원본은 여기 한 곳.

| | Claude Code | Codex |
|---|---|---|
| 전역 규칙 (`AGENTS.global.md`) | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| 스킬 (`skills/*`) | `~/.claude/skills/<이름>` | `~/.agents/skills/<이름>` |
| 프로젝트 규칙 | 각 프로젝트의 `CLAUDE.md` | 같은 `CLAUDE.md` 를 읽음 — install 이 `~/.codex/config.toml` 에 `project_doc_fallback_filenames = ["CLAUDE.md"]` 추가 |
| PC 별 경로 매핑 | `~/.ai-setup/paths.local.md` (자동 import) | 같은 파일 (규칙에 "직접 읽어라"로 명시 — Codex 는 import 없음) |
| 스킬 호출 | 자동 / `/스킬이름` | 자동 / `$스킬이름` |

## 설치

```bash
# Linux / macOS / NAS  (심볼릭 링크 — git pull 만 하면 반영)
git clone https://github.com/arusestech/ai-setup.git && cd ai-setup
./install.sh --status     # 먼저: 현재 상태만 확인 (아무것도 안 바꿈)
./install.sh

# Windows  (복사 — git pull 후 다시 실행)
git clone https://github.com/arusestech/ai-setup.git && cd ai-setup
install.bat check         # 먼저: 무엇이 바뀌는지만 보여 준다 (아무것도 안 바꿈)
install.bat
```

`./install.sh --no-codex` / `--no-claude` 로 한쪽만 설치할 수 있다. Codex 가 아직 설치돼 있지 않아도 폴더만 미리 만들어 두므로 나중에 설치하면 바로 적용된다. 설치 후 에이전트 재시작.

### 이미 에이전트를 쓰던 PC 에 설치할 때
- **기존 `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` 는 `~/.ai-setup/backup-<시각>/` 으로 옮겨지고 이 레포 것으로 교체된다.** 그 PC 에만 있던 규칙이 필요하면 설치 후 에이전트에게 "백업 폴더의 예전 CLAUDE.md/AGENTS.md 에서 아직 필요한 규칙을 ai-setup 의 AGENTS.global.md 에 합쳐줘" 라고 시키고 커밋한다(그래야 모든 PC 에 반영).
- 이 레포와 **이름이 같은 스킬만** 교체(백업 후)된다. 다른 스킬·`settings.json`·MCP 등록·메모리·로그인 정보는 건드리지 않는다.
- Codex `config.toml` 이 이미 있으면: Linux 는 맨 위에 fallback 한 줄을 추가(원본 `config.toml.bak-ai-setup`), Windows 는 추가할 줄을 안내만 한다.

### PC 마다 폴더가 다를 때 — `~/.ai-setup/paths.local.md`
규칙·스킬 본문은 NAS 경로(`/volume2/claude/...`)로 적혀 있고, 에이전트는 `~/.ai-setup/paths.local.md` 의 매핑 표를 보고 **그 PC 의 실제 경로로 바꿔 읽는다.** install 이 `paths.local.example.md` 로부터 한 번만 만들고 이후 덮어쓰지 않는다(레포에 커밋되지 않음). 설치 직후 표를 채운다 — 에이전트에게 "paths.local.md 채워줘, web-tester 는 D:\ai\webtester\wigo-web-tester 에 있고 …" 처럼 알려 줘도 된다. `wwt` 는 환경변수 `WWT_HOME`(web-tester 폴더)을 본다.

## 구성

| 경로 | 내용 |
|---|---|
| `AGENTS.global.md` | 전역 규칙 — ① "백그라운드로" = `bgrun` 사용(SSH 끊김 대비) ② 웹 메뉴 테스트는 WIGO Web Tester(`wwt`)로 실행하고 요약만 읽는다(에이전트가 playwright MCP 로 직접 순회 금지) ③ 두 에이전트 공존 규칙 |
| `skills/defect-fix/` | 결함 접수→분석 문서→수정→수정소스 패키지. 프로젝트별 형식은 `references/`(wrb_voc, scbk_voc), 패키지 생성은 `scripts/make_fix_package.py`(표준 라이브러리만, OS 무관) |
| `skills/systematic-debugging/` | 근본 원인 조사 없이 수정 금지 4단계. obra/superpowers v6.4.1(MIT)에서 복사, 다른 superpowers 스킬 참조 2줄만 독립 문구로 수정 |
| `skills/verification-before-completion/` | 완료 주장 전 실제 검증 실행. obra/superpowers v6.4.1(MIT) 그대로 |
| `bin/bgrun` | 명령을 세션과 분리해 실행(setsid+nohup), 로그·종료코드 `~/bg-jobs/`. **Linux/macOS 전용** |
| `bin/ct` · `bin/cxt` | Claude(`ct`) / Codex(`cxt`) 를 tmux 세션 안에서 실행·복귀. tmux 필요. **Linux/macOS 전용** |
| `bin/wwt` | [web-tester](https://github.com/arusestech/web-tester) 래퍼: `run` / `bg` / `summary`(❌·⚠️ 만 요약) / `ls`. bash 필요(Windows 는 Git Bash, 또는 web-tester 의 `run.bat`) |
| `tmux.conf` | `~/.tmux.conf` — 마우스 스크롤, 스크롤백 5만 줄, ESC 지연 제거 |
| `shell/bashrc-snippet.sh` | (수동) `~/.bashrc` 에 붙이는 조각 — PATH, SSH 로그인 시 tmux 세션·bgrun 작업 안내 |
| `mcp/playwright.md` | (수동) playwright MCP 등록 명령 — Claude / Codex, Linux·NAS / Windows |
| `paths.local.example.md` | PC 별 경로 매핑 파일의 예시 |

스킬은 에이전트 중립적으로 쓴다: 특정 에이전트의 도구 이름에 의존하는 절차를 넣지 않고, 다른 스킬은 이름으로만 가리킨다.

## 함께 받아야 하는 것

- `web-tester` 레포 클론 후 `npm ci` (브라우저가 없으면 `npx playwright install chromium`).
- 프로젝트별 접속 URL·계정·금지 행위는 각 프로젝트 레포의 `CLAUDE.md` / `CLAUDE.local.md` 에 둔다. **비밀번호·토큰은 이 레포에 넣지 않는다.**
- 에이전트 메모리·대화 기록은 PC 별 상태라 이 레포에 포함하지 않는다. (Claude 메모리는 Codex 가 못 읽는다 — 두 에이전트가 모두 알아야 하는 사실은 프로젝트 `CLAUDE.md` 나 이 레포의 규칙에 적는다.)
- Codex 는 Git 루트보다 위 폴더의 규칙 파일을 읽지 않는다. NAS 의 공통 룰(`/volume2/claude/CLAUDE.md`)을 Codex 에도 적용하려면 Claude 와 똑같이 `/volume2/claude` 에서 실행한다.

## 고칠 때

스킬·규칙은 `~/.claude/`·`~/.codex/`·`~/.agents/` 쪽이 아니라 **이 레포의 파일**을 고친다(링크 설치면 같은 파일이다). 고친 뒤 커밋 → 다른 PC 에서 `git pull`(Windows 는 `install.bat` 재실행).

superpowers 에서 가져온 스킬을 업스트림 새 버전으로 갱신할 때는 `systematic-debugging/SKILL.md` 의 로컬 수정 2줄(테스트 프레임워크 없는 레거시용 수동 재현 절차, 검증 문구)을 다시 적용한다.
