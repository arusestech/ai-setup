# ~/.bashrc 맨 아래에 붙여 넣는다 (Linux/NAS). SSH 로그인 시 살아 있는 tmux 세션·백그라운드 작업을 알려 준다.
export PATH="$HOME/.local/bin:$PATH"
# export WWT_HOME=/path/to/web-tester      # web-tester 가 /volume2/claude/web-tester 가 아닐 때
if [[ $- == *i* ]] && [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then
  _s=$(tmux ls -F '#S' 2>/dev/null | paste -sd' ')
  [ -n "$_s" ] && echo "▶ 살아 있는 tmux 세션: $_s  →  ct / cxt 로 복귀"
  _b=$(bgrun list 2>/dev/null | grep -c '실행중')
  [ "${_b:-0}" -gt 0 ] && echo "▶ 실행 중인 백그라운드 작업 ${_b}개  →  bgrun list"
  unset _s _b
fi
