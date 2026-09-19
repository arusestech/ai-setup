# playwright MCP 등록 (Claude Code · Codex, user 스코프)

메뉴 테스트는 WIGO Web Tester(`wwt`)로 하므로 MCP 는 **특정 화면을 직접 재현·관찰할 때만** 쓴다. 옵션은 토큰 절약 기준.

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

## Windows (설치된 Chrome 사용, 창 보임)
```bat
claude mcp remove playwright -s user
claude mcp add --scope user --transport stdio playwright -- "C:\Program Files\nodejs\node.exe" "%APPDATA%\npm\node_modules\@playwright\mcp\cli.js" --browser chrome --isolated --viewport-size 1920x1080 --image-responses omit --output-dir "%USERPROFILE%\playwright-output" --console-level error --ignore-https-errors --codegen none
```
확인: `claude mcp get playwright` → Connected. 옵션을 바꾸면 Claude Code 를 재시작해야 적용된다.

## Codex
Codex 는 `~/.codex/config.toml` 의 `[mcp_servers.<이름>]` 에 등록한다. CLI 로:
```bash
codex mcp add playwright -- <node 절대경로> <npm 전역>/node_modules/@playwright/mcp/cli.js --browser chromium --headless --isolated --viewport-size 1920x1080 --image-responses omit --output-dir <홈>/playwright-output --console-level error --ignore-https-errors --codegen none
codex mcp list
```
(Windows 는 위 Windows 절의 node/cli 경로와 `--browser chrome` 을 같은 순서로 넣는다.) Claude 와 같은 출력 폴더를 써도 된다.
