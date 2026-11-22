#!/bin/sh
# Claude Code status line, copied from the host's ~/.claude/settings.json.
# Reads the JSON payload from stdin.

input=$(cat)
j() { command -v jq >/dev/null 2>&1 && printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

cwd=$(j '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd=$PWD
case "$cwd" in
  "$HOME") short='~' ;;
  "$HOME"/*) short="~${cwd#"$HOME"}" ;;
  *) short=$cwd ;;
esac
[ ${#short} -gt 44 ] && short=".../$(basename "$cwd")"

model=$(j '.model.display_name // .model.id // empty')
[ -z "$model" ] && model=claude
ctx=$(j '.context_window.used_percentage // empty')
cost=$(j '.cost.total_cost_usd // empty')
five=$(j '.rate_limits.five_hour.used_percentage // empty')
style=$(j '.output_style.name // empty')
vm=$(j '.vim.mode // empty')
wt=$(j '.worktree.branch // empty')

out=''
add() {
  if [ -n "$1" ]; then
    if [ -n "$out" ]; then out="$out$(printf '\033[2m | \033[0m')"; fi
    out="$out$1"
  fi
}

add "$(printf '\033[96m%s\033[0m' "$short")"

branch=$(git --no-optional-locks -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  d=''
  if [ -n "$(git --no-optional-locks -C "$cwd" status --porcelain --untracked-files=no 2>/dev/null | head -n 1)" ]; then
    d='*'
  fi
  add "$(printf '\033[92m%s%s\033[0m' "$branch" "$d")"
fi

[ -n "$wt" ] && add "$(printf '\033[32mwt:%s\033[0m' "$wt")"
add "$(printf '\033[95m%s\033[0m' "$model")"

if [ -n "$ctx" ]; then
  ci=$(printf '%.0f' "$ctx" 2>/dev/null)
  if [ -n "$ci" ]; then
    if [ "$ci" -ge 85 ]; then cc=91
    elif [ "$ci" -ge 60 ]; then cc=93
    else cc=92
    fi
    add "$(printf '\033[%smctx %s%%\033[0m' "$cc" "$ci")"
  fi
fi

if [ -n "$cost" ]; then
  cf=$(printf '%.2f' "$cost" 2>/dev/null)
  [ -n "$cf" ] && add "$(printf '\033[37m$%s\033[0m' "$cf")"
fi

if [ -n "$five" ]; then
  fv=$(printf '%.0f' "$five" 2>/dev/null)
  [ -n "$fv" ] && add "$(printf '\033[94m5h %s%%\033[0m' "$fv")"
fi

if [ -n "$style" ] && [ "$style" != default ]; then
  add "$(printf '\033[2m%s\033[0m' "$style")"
fi
[ -n "$vm" ] && add "$(printf '\033[93m%s\033[0m' "$vm")"

printf '%s\n' "$out"
