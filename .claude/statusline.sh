#!/usr/bin/env bash
# Claude Code statusline. Reads the session JSON from stdin and prints two lines:
#   {Model} - {Effort} | {Folder} | {Branch}
#   [{bar}] {pct}% | {tokensUsed}/{contextWindow}
# Needs only bash, grep, sed and git (no jq). Fields that are missing are dropped.

# Set a color to an ANSI escape such as "\033[36m". Empty means no color.
COLOR_MODEL="\x1b[38;5;160m"
COLOR_EFFORT="\x1b[38;5;160m"
COLOR_DIRECTORY="\x1b[38;5;130m"
COLOR_BRANCH="\x1b[38;5;136m"
COLOR_BAR="\x1b[38;5;220m"
COLOR_TOKENS="\x1b[38;5;244m"

BAR_WIDTH=40
BAR_FILLED="█"
BAR_EMPTY="░"
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

# Prints "Model - Effort | Folder | Branch" with absent parts dropped.
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
      modelPart+=" - $(paint "$COLOR_EFFORT" "$effort")"
    fi
    segments+=("$modelPart")
  fi

  if [ -n "$dir" ]; then
    folder="${dir%/}"
    folder="${folder##*/}"
    segments+=("$(paint "$COLOR_DIRECTORY" "$folder")")
    branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
      segments+=("$(paint "$COLOR_BRANCH" "$branch")")
    fi
  fi

  local line="" segment
  for segment in "${segments[@]}"; do
    line+="${line:+ | }$segment"
  done
  printf '%s' "$line"
}

# Prints "[bar] pct% | used/window", or nothing when the window size is unknown.
buildSecondLine() {
  local json=$1
  local windowSize used pct
  windowSize=$(getNumber context_window_size "$json")
  [ -n "$windowSize" ] && [ "$windowSize" -gt 0 ] || return 0

  used=$(getNumber total_input_tokens "$json")
  used=${used:-0}
  pct=$((used * 100 / windowSize))
  [ "$pct" -gt 100 ] && pct=100

  printf '%s | %s' \
    "$(paint "$COLOR_BAR" "[$(buildBar "$pct")] ${pct}%")" \
    "$(paint "$COLOR_TOKENS" "$(formatTokens "$used")/$(formatTokens "$windowSize")")"
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
