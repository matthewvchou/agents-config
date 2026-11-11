#!/usr/bin/env bash
# Claude Code statusline. Reads the session JSON from stdin and prints two lines:
#   {Model} · {Effort} | {Folder} · {Branch} {✓ if nothing to commit, ✗ if not}
#   [{bar}] {pct}% · {tokensUsed}/{contextWindow} | 5h · {pct}% (↻ {time}) | 7d · {pct}% (↻ {time})
# Needs only bash, grep, sed, date and git (no jq). Fields that are missing are dropped.

# Set a color to an ANSI escape such as "\033[36m". Empty means no color.
COLOR_MODEL="\x1b[38;5;160m"
COLOR_EFFORT="\x1b[38;5;160m"
COLOR_DIRECTORY="\x1b[38;5;130m"
COLOR_BRANCH="\x1b[38;5;136m"
COLOR_BAR="\x1b[38;5;220m"
COLOR_TOKENS="\x1b[38;5;244m"
COLOR_LIMIT_5H="\x1b[38;5;186m"
COLOR_LIMIT_7D="\x1b[38;5;186m"
COLOR_LIMIT_RESET="\x1b[38;5;244m"
COLOR_GIT_CLEAN="\x1b[32m"
COLOR_GIT_DIRTY="\x1b[31m"

BAR_WIDTH=20
BAR_FILLED="█"
BAR_EMPTY="░"
GIT_CLEAN_MARK="✓"
GIT_DIRTY_MARK="✗"
RESET="\033[0m"

# Prints the first string value for a key, or nothing if the key is absent.
getString() {
  printf '%s' "$2" \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" \
    | head -n1 \
    | sed -E 's/^[^:]*:[[:space:]]*"//; s/"$//'
}

# Prints the first integer value for a key, or nothing if the key is absent.
getNumber() {
  printf '%s' "$2" \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*[0-9]+" \
    | head -n1 \
    | grep -oE '[0-9]+$'
}

# Prints the first number (decimals allowed) for a key inside a named object, or nothing.
# Scoping to the object keeps used_percentage here apart from the context window's own.
getObjectNumber() {
  printf '%s' "$3" \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\{[^}]*\}" \
    | head -n1 \
    | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*[0-9]+(\.[0-9]+)?" \
    | head -n1 \
    | grep -oE '[0-9]+(\.[0-9]+)?$'
}

# Rounds a non-negative decimal to the nearest whole number, with halves rounding up.
roundPercent() {
  local whole=${1%%.*}
  if [[ "$1" == *.* ]]; then
    local tenth=${1#*.}
    tenth=${tenth:0:1}
    [ "$tenth" -ge 5 ] && whole=$((whole + 1))
  fi
  printf '%s' "$whole"
}

# Formats seconds as the two largest non-zero units: 3d 4h, 2h 10m, 45m, <1m.
formatCountdown() {
  local secs=$1
  local days=$((secs / 86400))
  local hours=$(((secs % 86400) / 3600))
  local minutes=$(((secs % 3600) / 60))

  if [ "$days" -gt 0 ]; then
    printf '%sd' "$days"
    [ "$hours" -gt 0 ] && printf ' %sh' "$hours"
  elif [ "$hours" -gt 0 ]; then
    printf '%sh' "$hours"
    [ "$minutes" -gt 0 ] && printf ' %sm' "$minutes"
  elif [ "$minutes" -gt 0 ]; then
    printf '%sm' "$minutes"
  else
    printf '<1m'
  fi
}

# Wraps text in a color and a reset, or prints it unchanged when the color is empty.
paint() {
  if [ -z "$1" ]; then
    printf '%s' "$2"
  else
    printf '%b%s%b' "$1" "$2" "$RESET"
  fi
}

# Formats a token count: 850, 60k, 1M, 1.5M.
formatTokens() {
  local count=$1
  if [ "$count" -lt 1000 ]; then
    printf '%s' "$count"
  elif [ "$count" -lt 1000000 ]; then
    printf '%sk' $((count / 1000))
  else
    local whole=$((count / 1000000))
    local tenth=$(((count % 1000000) / 100000))
    if [ "$tenth" -eq 0 ]; then
      printf '%sM' "$whole"
    else
      printf '%s.%sM' "$whole" "$tenth"
    fi
  fi
}

# Prints a progress bar of BAR_WIDTH characters for a 0-100 percentage.
buildBar() {
  local filled=$(($1 * BAR_WIDTH / 100))
  local bar=""
  local i
  for ((i = 0; i < BAR_WIDTH; i++)); do
    if [ "$i" -lt "$filled" ]; then
      bar+="$BAR_FILLED"
    else
      bar+="$BAR_EMPTY"
    fi
  done
  printf '%s' "$bar"
}

# Prints a check mark when the working tree has nothing to commit, an x otherwise.
# Untracked files count as something to commit.
getGitStatusMark() {
  if [ -z "$(git -C "$1" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
    paint "$COLOR_GIT_CLEAN" "$GIT_CLEAN_MARK"
  else
    paint "$COLOR_GIT_DIRTY" "$GIT_DIRTY_MARK"
  fi
}

# Prints "Model · Effort | Folder · Branch status" with absent parts dropped.
buildFirstLine() {
  local json=$1
  local model effort dir folder branch
  local segments=()

  model=$(getString display_name "$json")
  effort=$(getString level "$(printf '%s' "$json" | grep -oE '"effort"[[:space:]]*:[[:space:]]*\{[^}]*\}' | head -n1)")
  # Windows paths arrive JSON-escaped (C:\\Users\\...), so collapse any run of backslashes to one slash.
  dir=$(getString current_dir "$json" | sed -E 's#\\+#/#g')

  if [ -n "$model" ]; then
    local modelPart
    modelPart=$(paint "$COLOR_MODEL" "$model")
    if [ -n "$effort" ]; then
      modelPart+=" · $(paint "$COLOR_EFFORT" "$effort")"
    fi
    segments+=("$modelPart")
  fi

  if [ -n "$dir" ]; then
    folder="${dir%/}"
    folder="${folder##*/}"
    local dirPart
    dirPart=$(paint "$COLOR_DIRECTORY" "$folder")
    branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
      dirPart+=" · $(paint "$COLOR_BRANCH" "$branch") $(getGitStatusMark "$dir")"
    fi
    segments+=("$dirPart")
  fi

  local line="" segment
  for segment in "${segments[@]}"; do
    line+="${line:+ | }$segment"
  done
  printf '%s' "$line"
}

# Prints "[bar] pct% · used/window", or nothing when the window size is unknown.
buildContextPart() {
  local json=$1
  local windowSize used pct
  windowSize=$(getNumber context_window_size "$json")
  [ -n "$windowSize" ] && [ "$windowSize" -gt 0 ] || return 0

  used=$(getNumber total_input_tokens "$json")
  used=${used:-0}
  pct=$((used * 100 / windowSize))
  [ "$pct" -gt 100 ] && pct=100

  printf '%s · %s' \
    "$(paint "$COLOR_BAR" "[$(buildBar "$pct")] ${pct}%")" \
    "$(paint "$COLOR_TOKENS" "$(formatTokens "$used")/$(formatTokens "$windowSize")")"
}

# Prints "Label · pct% (↻ time)", or nothing when the window is absent or already expired.
# Without resets_at, only the "(↻ ...)" part is dropped.
buildLimitPart() {
  local label=$1 color=$2 objectName=$3 json=$4
  local pct resetsAt remaining text

  pct=$(getObjectNumber "$objectName" used_percentage "$json")
  [ -n "$pct" ] || return 0
  text=$(paint "$color" "$label · $(roundPercent "$pct")%")

  resetsAt=$(getObjectNumber "$objectName" resets_at "$json")
  if [ -n "$resetsAt" ]; then
    remaining=$((${resetsAt%%.*} - $(date +%s)))
    [ "$remaining" -gt 0 ] || return 0
    text+=" $(paint "$COLOR_LIMIT_RESET" "(↻ $(formatCountdown "$remaining"))")"
  fi

  printf '%s' "$text"
}

# Prints the context part and both limit parts joined by " | ", with absent parts dropped.
buildSecondLine() {
  local json=$1
  local parts=() part line=""

  parts+=("$(buildContextPart "$json")")
  parts+=("$(buildLimitPart "5h" "$COLOR_LIMIT_5H" five_hour "$json")")
  parts+=("$(buildLimitPart "7d" "$COLOR_LIMIT_7D" seven_day "$json")")

  for part in "${parts[@]}"; do
    [ -n "$part" ] && line+="${line:+ | }$part"
  done
  printf '%s' "$line"
}

main() {
  local json firstLine secondLine
  json=$(cat | tr -d '\r\n')

  firstLine=$(buildFirstLine "$json")
  secondLine=$(buildSecondLine "$json")

  [ -n "$firstLine" ] && printf '%s\n' "$firstLine"
  [ -n "$secondLine" ] && printf '%s\n' "$secondLine"
  return 0
}

main
