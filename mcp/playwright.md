# playwright MCP 등록 (Claude Code · Codex, user 스코프)

메뉴 테스트는 WIGO Web Tester(`wwt`)로 하므로 MCP 는 **특정 화면을 직접 재현·관찰할 때만** 쓴다. 옵션은 토큰 절약 기준.

**이 문서가 모든 PC 의 기준이다.** 에이전트는 playwright MCP 를 등록·점검하거나 쓰기 전에 `claude mcp get playwright`(Codex 는 `codex mcp list`) 결과를 그 PC 환경(Linux·NAS / Windows) 절과 비교하고, 다르면 사용자에게 차이를 알린 뒤 아래 명령으로 다시 등록한다. 경로 부분(node·cli·출력 폴더)만 그 PC 에 맞게 바꾸고 옵션은 그대로 둔다. 출력 폴더는 `~/.ai-setup/paths.local.md` 의 "playwright 출력 폴더" 행에 기록한다. 옵션을 바꾸고 싶으면 PC 에서만 바꾸지 말고 이 문서를 고쳐 커밋한다.

## 공통 준비
```
npm i -g @playwright/mcp          # NAS 는 program/node 전역에 설치돼 있음
```

## Linux / NAS (headless, 내장 chromium)
```bash
claude mcp remove playwright -s user 2>/dev/null
claude mcp add-json -s user playwright '{"type":"stdio","command":"<node 절대경로>","args":["<npm 전역>/node_modules/@playwright/mcp/cli.js","--browser","chromium","--headless","--isolated","--viewport-size","1920x1080","--image-responses","omit","--output-dir","<홈>/playwright-output","--console-level","error","--ignore-https-errors","--codegen","none"],"env":{}}'
```
NAS 실제 값: node=`/volume2/claude-home/program/node/bin/node`, cli=`/volume2/claude-home/program/node/lib/node_modules/@playwright/mcp/cli.js`, output=`/volume2/claude-home/playwright-output`.

## Windows (설치된 Chrome 사용, 창 보임, 영구 프로필)
```bat
claude mcp remove playwright -s user
claude mcp add --scope user --transport stdio playwright -- "C:\Program Files\nodejs\node.exe" "%APPDATA%\npm\node_modules\@playwright\mcp\cli.js" --browser chrome --viewport-size 1920x1080 --image-responses omit --output-dir "%USERPROFILE%\playwright-output" --console-level error --ignore-https-errors --codegen none
```
Windows 는 `--isolated` 를 **넣지 않는다**: MCP 전용 영구 프로필을 써서 MCP 브라우저 안에서 한 로그인이 세션 간 유지되게 한다(평소 쓰는 Chrome 프로필과는 별개). 대신 두 세션이 동시에 MCP 브라우저를 띄우면 프로필 잠금으로 실패하니 한 번에 한 세션만 쓴다. (PowerShell 에서 실행할 때는 `%APPDATA%`·`%USERPROFILE%` 대신 `$env:APPDATA`·`$HOME`.)
확인: `claude mcp get playwright` → Connected. 옵션을 바꾸면 Claude Code 를 재시작해야 적용된다.

## Codex
Codex 는 `~/.codex/config.toml` 의 `[mcp_servers.<이름>]` 에 등록한다. CLI 로:
```bash
codex mcp add playwright -- <node 절대경로> <npm 전역>/node_modules/@playwright/mcp/cli.js --browser chromium --headless --isolated --viewport-size 1920x1080 --image-responses omit --output-dir <홈>/playwright-output --console-level error --ignore-https-errors --codegen none
codex mcp list
```
(Windows 는 위 Windows 절의 node/cli 경로와 옵션 — `--browser chrome`, `--isolated` 없음 — 을 같은 순서로 넣는다.) Claude 와 같은 출력 폴더를 써도 된다.
