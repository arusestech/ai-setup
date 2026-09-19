#!/usr/bin/env bash
# ai-setup 설치 (Linux / macOS / Git Bash) — 이 레포의 스킬·명령·전역 규칙을 Claude Code 와 Codex 양쪽에 연결한다.
#
#   ./install.sh              심볼릭 링크로 연결 (기본 — 레포를 git pull 하면 바로 반영)
#   ./install.sh --copy       복사 (링크를 못 쓰는 환경: Windows Git Bash 등). pull 후 다시 실행해야 반영됨
#   ./install.sh --status     현재 연결 상태만 출력 (아무것도 안 바꿈)
#   ./install.sh --uninstall  이 레포를 가리키는 링크만 제거 (백업은 복원하지 않음)
#   --no-codex / --no-claude  한쪽만 설치
#
# 기존 파일이 있으면 지우지 않고 ~/.ai-setup/backup-<시각>/ 으로 옮긴 뒤 연결한다.
# PC 별 경로 매핑 ~/.ai-setup/paths.local.md 는 한 번만 만들고 이후 덮어쓰지 않는다.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
AGENTS_SKILLS="$HOME/.agents/skills"        # Codex 사용자 스킬 위치
LOCAL_DIR="$HOME/.ai-setup"
BIN_DIR="$HOME/.local/bin"
MODE="link"; ACTION="install"; DO_CLAUDE=1; DO_CODEX=1
for a in "$@"; do case "$a" in
  --copy) MODE="copy" ;; --status) ACTION="status" ;; --uninstall) ACTION="uninstall" ;;
  --no-codex) DO_CODEX=0 ;; --no-claude) DO_CLAUDE=0 ;;
  -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;; esac; done
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) WIN=1; [ "$ACTION" = install ] && [ "$MODE" = link ] && { MODE="copy"; echo "Windows 셸 감지 → 복사 모드로 설치합니다."; } ;; *) WIN=0 ;; esac
BACKUP="$LOCAL_DIR/backup-$(date +%Y%m%d-%H%M%S)"

# 대상 목록: "원본(레포 상대경로)|설치 위치|백업 하위폴더"
targets() {
  for d in "$REPO"/skills/*/; do n=$(basename "$d")
    [ "$DO_CLAUDE" = 1 ] && echo "skills/$n|$CLAUDE_DIR/skills/$n|claude/skills"
    [ "$DO_CODEX" = 1 ]  && echo "skills/$n|$AGENTS_SKILLS/$n|codex/skills"
  done
  [ "$DO_CLAUDE" = 1 ] && echo "AGENTS.global.md|$CLAUDE_DIR/CLAUDE.md|claude"
  [ "$DO_CODEX" = 1 ]  && echo "AGENTS.global.md|$CODEX_DIR/AGENTS.md|codex"
  if [ "$WIN" = 0 ]; then
    for f in "$REPO"/bin/*; do echo "bin/$(basename "$f")|$BIN_DIR/$(basename "$f")|bin"; done
    echo "tmux.conf|$HOME/.tmux.conf|home"
  else
    echo "bin/wwt|$BIN_DIR/wwt|bin"          # bgrun·ct·cxt 는 Linux/macOS 전용
  fi
}

state_of() { # $1=src(절대) $2=dst
  if [ -L "$2" ] && [ "$(readlink -f "$2")" = "$(readlink -f "$1")" ]; then echo "링크됨"
  elif [ -e "$2" ] && diff -rq "$1" "$2" >/dev/null 2>&1; then echo "복사본(동일)"
  elif [ -e "$2" ] || [ -L "$2" ]; then echo "다름/다른 파일"
  else echo "없음"; fi
}

codex_fallback_state() {
  if [ ! -f "$CODEX_DIR/config.toml" ]; then echo "config.toml 없음"
  elif grep -q '^[[:space:]]*project_doc_fallback_filenames' "$CODEX_DIR/config.toml"; then
    grep -q 'CLAUDE\.md' "$CODEX_DIR/config.toml" && echo "설정됨" || echo "다른 값으로 설정돼 있음(수동 확인)"
  else echo "미설정"; fi
}

if [ "$ACTION" = status ]; then
  targets | while IFS='|' read -r s d _; do printf '%-16s %s\n' "$(state_of "$REPO/$s" "$d")" "$d"; done
  [ -e "$LOCAL_DIR/paths.local.md" ] && echo "있음             $LOCAL_DIR/paths.local.md" || echo "없음             $LOCAL_DIR/paths.local.md"
  [ "$DO_CODEX" = 1 ] && printf '%-16s %s\n' "$(codex_fallback_state)" "$CODEX_DIR/config.toml : project_doc_fallback_filenames=[\"CLAUDE.md\"]"
  exit 0
fi

if [ "$ACTION" = uninstall ]; then
  targets | while IFS='|' read -r s d _; do
    if [ -L "$d" ] && [ "$(readlink -f "$d")" = "$(readlink -f "$REPO/$s")" ]; then rm "$d" && echo "링크 제거: $d"; fi
  done; exit 0
fi

mkdir -p "$LOCAL_DIR" "$BIN_DIR"
[ "$DO_CLAUDE" = 1 ] && mkdir -p "$CLAUDE_DIR/skills"
[ "$DO_CODEX" = 1 ]  && mkdir -p "$CODEX_DIR" "$AGENTS_SKILLS"
chmod +x "$REPO"/bin/* "$REPO"/install.sh "$REPO"/skills/*/scripts/* 2>/dev/null
targets | while IFS='|' read -r s d sub; do
  src="$REPO/$s"; st=$(state_of "$src" "$d")
  if [ "$st" = "링크됨" ] && [ "$MODE" = link ]; then echo "유지   $d"; continue; fi
  if [ -e "$d" ] || [ -L "$d" ]; then
    if [ "$st" = "다름/다른 파일" ]; then mkdir -p "$BACKUP/$sub"; mv "$d" "$BACKUP/$sub/$(basename "$d")" && echo "백업   $d → $BACKUP/$sub/"
    else rm -rf "$d"; fi
  fi
  if [ "$MODE" = link ]; then ln -s "$src" "$d" && echo "링크   $d → $src"
  else cp -R "$src" "$d" && echo "복사   $d"; fi
done

# PC 별 경로 매핑 — 없을 때만 예시에서 만든다 (예전 위치 ~/.claude/paths.local.md 가 있으면 옮겨 온다)
if [ ! -e "$LOCAL_DIR/paths.local.md" ]; then
  if [ -f "$CLAUDE_DIR/paths.local.md" ]; then mv "$CLAUDE_DIR/paths.local.md" "$LOCAL_DIR/paths.local.md" && echo "이동   $CLAUDE_DIR/paths.local.md → $LOCAL_DIR/"
  else cp "$REPO/paths.local.example.md" "$LOCAL_DIR/paths.local.md" && echo "생성   $LOCAL_DIR/paths.local.md  ← 이 PC 의 실제 경로를 채우세요 (에이전트에게 \"paths.local.md 채워줘\" 라고 해도 됨)"; fi
else echo "유지   $LOCAL_DIR/paths.local.md (PC 별 파일, 덮어쓰지 않음)"; fi

# Codex 가 프로젝트의 CLAUDE.md 를 AGENTS.md 대신 읽게 한다. TOML 최상위 키는 첫 [table] 보다 앞에 있어야 하므로 파일 맨 위에 넣는다.
if [ "$DO_CODEX" = 1 ]; then
  cfg="$CODEX_DIR/config.toml"; line='project_doc_fallback_filenames = ["CLAUDE.md"]'
  case "$(codex_fallback_state)" in
    "config.toml 없음") printf '%s\n' "$line" > "$cfg" && echo "생성   $cfg ($line)" ;;
    "미설정") cp "$cfg" "$cfg.bak-ai-setup" && { printf '%s\n' "$line"; cat "$cfg.bak-ai-setup"; } > "$cfg" && echo "추가   $cfg 맨 위에 $line (원본: config.toml.bak-ai-setup)" ;;
    "설정됨") echo "유지   $cfg (fallback 이미 설정됨)" ;;
    *) echo "※ $cfg 의 project_doc_fallback_filenames 에 \"CLAUDE.md\" 를 직접 추가하세요" ;;
  esac
fi

case ":$PATH:" in *":$BIN_DIR:"*) ;; *) echo; echo "※ $BIN_DIR 이 PATH 에 없습니다 → shell/bashrc-snippet.sh 참고" ;; esac
echo
echo "완료. 남은 수동 단계:"
echo " - $LOCAL_DIR/paths.local.md 에 이 PC 의 실제 폴더를 채운다 (wwt 는 환경변수 WWT_HOME=<web-tester 폴더>)"
echo " - playwright MCP 등록(선택): $REPO/mcp/playwright.md — Claude / Codex 각각"
echo " - Claude Code / Codex 를 재시작하면 스킬·규칙이 로드됩니다."
