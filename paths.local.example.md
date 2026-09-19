# 이 PC 의 경로 매핑 (~/.ai-setup/paths.local.md)

> `ai-setup` 의 전역 규칙·스킬은 NAS 기준 경로(`/volume2/claude/...`)로 적혀 있다. **이 PC 에서는 아래 표의 실제 경로로 바꿔 읽는다.** 표에 없는 프로젝트는 사용자에게 위치를 묻고 이 파일에 추가한다. 이 파일은 PC 마다 다르며 레포에 커밋하지 않는다(install 이 덮어쓰지 않음).

- OS / 셸: (예: Windows 11, PowerShell · Git Bash 있음)
- `bgrun` · `ct` · tmux: (Linux/macOS 만. Windows 면 "없음 — 백그라운드 절은 건너뛴다. 오래 걸리는 작업은 Bash 도구의 run_in_background 사용")

| 논리 이름 (NAS 기준 경로) | 이 PC 의 실제 경로 |
|---|---|
| ai-setup 레포 (이 규칙·스킬·`mcp/playwright.md` 원본) | |
| 작업 루트 (`/volume2/claude`) | |
| web-tester (`/volume2/claude/web-tester`) | |
| wrb_voc 참고자료 (`/volume2/claude/wrb_voc`) | |
| wrb_voc 소스 (`/volume2/claude/repo/wrb_voc`) | |
| scbk_voc 참고자료 (`/volume2/claude/scbk_voc`) | |
| SCBK_VOC 소스 (`/volume2/claude/repo/SCBK_VOC`) | |
| SCBK-VOC-BATCH 소스 (`/volume2/claude/repo/SCBK-VOC-BATCH`) | |
| starbucks_voc 참고자료 (`/volume2/claude/starbucks_voc`) | |
| STARBUCKS-VOC-MASTER / BATCH 소스 (`/volume2/claude/repo/STARBUCKS-VOC-*`) | |
| 개발 도구 (`/volume2/claude-home/program` — JDK, Maven, Tomcat, Python, Node) | (예: 시스템 설치 사용 — JAVA_HOME=…, mvn 은 PATH) |
| playwright 출력 폴더 (`/volume2/claude-home/playwright-output`) | (등록 옵션은 `mcp/playwright.md` 기준 — 여기엔 폴더만) |

## web-tester 실행 방법 (이 PC)
- (예: Windows → `<web-tester>\run.bat <시나리오> --headless …`, 결과 요약은 Git Bash 에서 `WWT_HOME=<web-tester> wwt summary` 또는 `reports\...\report.json` 의 status≠ok 항목만 읽기)
