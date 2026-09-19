# 전역 작업 규칙

> 이 파일은 **Claude Code 와 Codex 가 함께 쓰는** 전역 규칙이다. 원본은 개인 레포 `ai-setup` 의 `AGENTS.global.md` 이며 install 이 `~/.claude/CLAUDE.md`(Claude) 와 `~/.codex/AGENTS.md`(Codex) 로 연결·복사한다. 고칠 때는 레포 쪽을 고치고 커밋한다(사용자 승인 후).
> **경로 해석**: 본문의 `/volume2/claude/...`, `/volume2/claude-home/...` 는 원래 NAS 환경 기준이다. **이 PC 의 실제 경로·OS·사용 가능한 도구는 `~/.ai-setup/paths.local.md` 를 따른다**(PC 마다 폴더가 다름). Claude 는 아래 import 로 자동 로드되고, **Codex 는 import 가 없으므로 경로가 필요한 작업을 시작할 때 그 파일을 직접 읽는다.** 파일이 없거나 필요한 프로젝트가 표에 없으면 추측하지 말고 사용자에게 위치를 물어 그 파일에 기록한다. `bgrun`·`ct`·`cxt`·tmux 는 Linux/macOS 전용이며 Windows 로컬 작업에서는 해당 절을 건너뛴다(SSH 끊김 문제가 없음).
> **두 에이전트 공존**: 같은 레포를 Claude 와 Codex 가 번갈아 작업한다. 작업 시작 전 `git status`/`git log` 로 내가 모르는 변경이 있는지 보고, 모르는 변경은 임의로 되돌리지 않는다. 스킬은 공용이다(Claude `~/.claude/skills`, Codex `~/.agents/skills` → 같은 레포 폴더).

@~/.ai-setup/paths.local.md

## 백그라운드 실행 (SSH 끊김 대비)

사용자는 외부에서 cloudflared SSH 로 접속하며 연결이 자주 끊긴다. 끊기면 에이전트(Claude/Codex) 프로세스와 그 자식(에이전트 셸 도구의 백그라운드 실행 — Claude 의 `run_in_background` 등 — 포함)이 같이 죽는다.

- 사용자가 **"백그라운드로"**, "백에서 돌려", "끊겨도 돌게" 라고 하면 셸 도구 자체의 백그라운드 기능(`run_in_background`)이나 `&` 를 쓰지 말고 **반드시 `bgrun`** 으로 실행한다: `bgrun -n <짧은이름> [-C 작업폴더] -- '<명령>'`. setsid+nohup 으로 세션과 완전히 분리되고 로그·종료 코드가 `~/bg-jobs/<이름>/` 에 남는다.
- 요청이 없어도 오래 걸리는 작업(빌드, 서버 기동, 배치, 대량 변환, STT 등 대략 2분 이상)은 `bgrun` 으로 돌린다. Tomcat/WildFly 등 서버 기동도 마찬가지.
- 시작 직후 **작업 이름과 로그 경로를 사용자에게 알려준다.** 진행 확인은 `bgrun tail <이름>` / `bgrun status <이름>`, 중지는 `bgrun stop <이름>`, 목록은 `bgrun list`. 결과를 기다려야 하면 `bgrun status` 를 간격을 두고 확인하되, 끊겨도 작업은 계속된다는 점을 전제로 한다.
- 새 세션을 시작했는데 사용자가 "아까 돌리던 거", "백그라운드 작업 어떻게 됐어" 라고 하면 먼저 `bgrun list` 와 해당 로그를 확인한다.
- `bgrun` 은 **셸 명령**만 분리한다. 에이전트가 직접 판단하며 진행해야 하는 작업(코드 수정, 메뉴 테스트 등)은 에이전트 프로세스가 살아 있어야 하므로, 사용자가 `ct`(tmux 안에서 Claude 실행) / `cxt`(tmux 안에서 Codex 실행) 로 접속했는지에 달려 있다. 환경변수 `TMUX` 가 비어 있는 세션에서 긴 에이전트 작업을 요청받으면 "`ct`/`cxt` 로 접속하면 끊겨도 이어진다"고 한 줄 안내한다. 끊긴 뒤 복귀: SSH 재접속 → `ct`(또는 `cxt`). tmux 밖에서 죽은 대화는 `claude --continue` / `codex resume` 으로 이어간다.
- 도구 위치: `~/.local/bin/bgrun`, `~/.local/bin/ct`, `~/.local/bin/cxt`, tmux 3.3a 는 `program/tmux`(deb 추출 포터블), 설정 `~/.tmux.conf`.

## 웹 메뉴 테스트 (Java/JSP 프로젝트)

"메뉴 테스트", "화면 테스트", "메뉴 순회", "프로젝트 테스트" 요청을 받으면 **에이전트(Claude/Codex)가 playwright MCP 로 직접 순회하지 않는다(토큰 과다).** 사용자가 만든 **WIGO Web Tester**(`/volume2/claude/web-tester`, 런타임에 AI 없음)로 실행하고, 에이전트는 **시나리오 작성·실행·결과 요약 해석**만 한다. 도구 사용법·시나리오 형식은 그 폴더의 `CLAUDE.md` → `docs/HANDOVER.md` → `docs/시나리오-작성-가이드.md` 를 따른다.

### 도구
- `wwt` (`~/.local/bin/wwt`, web-tester 래퍼 — 어느 폴더에서든 실행 가능):
  - `wwt ls` 시나리오 목록 / `wwt lint <시나리오|폴더>` 사전 검사
  - `wwt run <시나리오.json|폴더> [--mode menus|crud|all] [--only 이름] [--screenshot fail] [--rerun-failed]` — headless 실행(자동으로 `--headless` 붙음). 경로는 web-tester 기준(`scenarios/<프로젝트>/<폴더>/<이름>.json`)
  - `wwt bg <…같은 인자>` — `bgrun` 으로 세션과 무관하게 실행. **메뉴가 많거나(대략 20개↑) 일괄 실행이면 항상 `wwt bg`** 로 돌리고 `bgrun status/tail` 로 끝났는지만 확인한다 (config 기본 속도가 "느림" 이라 오래 걸린다)
  - `wwt summary [증적폴더]` — 최근 `report.json` 에서 **요약 + ❌/⚠️ 항목만** 출력. 결과 확인은 이것으로 한다. `report.json`/`report.md`/`report.html` 전체를 Read 하지 않는다
  - 그 외 인자는 `cli.js` 로 그대로 전달: `wwt scan-source <소스폴더> --out scenarios/<프로젝트>/<이름>.json`, `wwt discover …`, `wwt --help`
- 비밀번호는 시나리오에 쓰지 않는다(`{{password}}`). 실행 시 환경변수 `WWT_password=… wwt run …` 로 준다. 계정·비밀번호는 프로젝트 `CLAUDE.md`/`CLAUDE.local.md`, 또는 `scenarios/<프로젝트>/README.md`·`_project.json` 에서 찾고, 없으면 사용자에게 묻는다.
- NAS 환경: `node_modules` 는 `npm ci` 로 설치됨(playwright 1.62.1), 브라우저는 `~/.cache/ms-playwright` 의 chromium 1234 를 쓴다(→ 지우지 않는다. `program/venv/scbk_voc` 의 Python Playwright 도 같은 것을 씀). GUI(`wigo-web-tester.sh`)는 NAS 에서 쓰지 않는다 — 터미널 실행만.

### 절차
1. **사전 확인**: 프로젝트 `CLAUDE.md` 에서 접속 URL·기동 방법·금지 행위 확인. 서버가 안 떠 있으면 기동(오래 걸리면 `bgrun`) 후 URL 응답 확인.
2. **시나리오 확인**: `wwt ls` 로 해당 프로젝트 시나리오가 있는지 본다(현재: 우리은행VOC, 스타벅스, SCBK_*, 기본). 있으면 그대로 쓴다. 없으면 web-tester `CLAUDE.md` 의 "시나리오 작성 절차"대로 `wwt scan-source` 초안 → 검토·보완 → `wwt lint` → `--only <메뉴 하나>` 로 로그인부터 확인.
3. **실행**: 기본은 `--mode menus --screenshot fail`. CRUD 는 요청받았을 때만(`--mode crud|all`). 재확인은 `--rerun-failed` 또는 `--only`. `forbidden` 을 푸는 `allowForbidden` 흐름은 사용자 확인 없이 만들지 않는다.
4. **결과 해석**: `wwt summary` 출력만 보고 ❌/⚠️ 를 **서버 버그 / 시나리오 오류(셀렉터·expect) / 환경 노이즈** 로 분류한다. `triage` 는 규칙 기반 1차 분류일 뿐이니 확정 전에 근거를 본다 — 필요한 항목만 스크린샷 파일을 Read, 직전 비교가 있으면 **신규 실패를 먼저** 본다.
5. **서버 로그 대조**: 5xx/에러 페이지/AJAX 실패 항목은 같은 시각의 서버 로그(Tomcat `logs/catalina.out`, `localhost.*.log`, 앱 로그 — 위치는 프로젝트 `CLAUDE.md`)에서 스택트레이스와 의심 소스 위치(파일:라인)를 확보한다. 원인 분석은 `systematic-debugging` 스킬 절차를 따른다.
6. 시나리오 오류로 판정된 것은 시나리오를 고쳐 `--rerun-failed` 로 재확인한다. **도구 본체(`src/`, `ui/`)는 프로젝트 때문에 고치지 않는다.** 도구 자체를 고쳐 달라는 요청이면 `docs/HANDOVER.md` 변경 이력에 추가한다.

### playwright MCP 는 언제 쓰나
- 기본적으로 쓰지 않는다. **사용자가 명시적으로 요청했거나**, web-tester 결과의 특정 실패 1~2건을 화면에서 직접 재현·관찰해야 원인을 알 수 있을 때만 그 화면에 한해 쓴다. 메뉴 순회·회귀 테스트 용도로는 쓰지 않는다.
- **등록 옵션의 기준은 `ai-setup` 레포의 `mcp/playwright.md`** 다(레포 위치는 `paths.local.md` 의 "ai-setup 레포" 행). 환경별로 다르다 — Linux·NAS 는 headless·`--isolated`, Windows 는 설치된 Chrome·`--isolated` 없음(영구 프로필). MCP 를 등록·점검하거나 쓰기 전에 `claude mcp get playwright`(Codex 는 `codex mcp list`)를 그 문서와 비교하고, 다르면 사용자에게 알린 뒤 문서대로 다시 등록한다. 옵션을 바꿀 때는 PC 설정만 바꾸지 말고 그 문서를 고쳐 커밋한다.
- 쓸 때: 전체 스냅샷은 최소화(`browser_evaluate`·`browser_find` 우선), 스크린샷은 출력 폴더(`/volume2/claude-home/playwright-output/`, 다른 PC 는 `paths.local.md`)에 파일로만 저장된다(`--image-responses omit`).

### 결과 보고 형식
- 요약 한 줄(전체 N개 중 정상/실패/주의, 직전 대비 신규 실패/해결) + 증적 폴더 경로. 표는 다시 만들지 말고 `defects.csv`·`report.html` 경로를 안내한다.
- ❌/⚠️ 만 표로: `메뉴명 | URL | 결과 | 확정 분류 | 증상 요약`
- 서버 버그로 확정한 항목은 아래에 상세: 재현 경로, 에러 메시지/스택트레이스, 스크린샷 경로, 의심되는 소스 위치(파일:라인)
- 요청 없이는 소스를 수정하지 않는다. 수정 제안만 한다.
