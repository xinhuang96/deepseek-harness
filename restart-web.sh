#!/usr/bin/env bash
# Restart the web server running inside a screen session.
# Usage: ./restart-web.sh [session_name] [project_dir]

SELF="$(readlink -f "$0")"
SESSION="${1:-573697.pts-3.ubuntu}"          # screen session name
APP_DIR="${2:-$(dirname "$SELF")}"            # folder where you run pnpm
CMD="pnpm dsh web --no-open"
LOG="/tmp/restart-web.log"

# Step 1: re-launch this script fully detached from the current shell.
if [ -z "$RESTART_WEB_DETACHED" ]; then
  export RESTART_WEB_DETACHED=1
  setsid nohup "$SELF" "$SESSION" "$APP_DIR" >>"$LOG" 2>&1 </dev/null &
  echo "Restart started in background. Log: $LOG"
  exit 0
fi

# From here on we run in the background, independent of the shell.
echo "=== $(date) restarting '$SESSION' ==="
sleep 2   # let the calling shell return first

session_exists() {
  screen -ls | awk -v s="$SESSION" '
    { name = $1; short = name; sub(/^[0-9]+\./, "", short) }
    name == s || short == s { found = 1 }
    END { exit !found }'
}

server_running() {
  pgrep -u "$(id -u)" -f "dsh web" | grep -vx "$$" >/dev/null
}

if session_exists; then
  echo "Sending Ctrl+C to screen session '$SESSION'..."
  screen -S "$SESSION" -p 0 -X stuff $'\003'

  # Wait up to 30s for the server process to exit
  for i in $(seq 1 30); do
    server_running || break
    sleep 1
  done
  sleep 2
else
  echo "Session '$SESSION' not found."
fi

if session_exists; then
  echo "Starting server inside existing session..."
  screen -S "$SESSION" -p 0 -X stuff "cd \"$APP_DIR\" && $CMD"$'\n'
else
  echo "Creating new detached session 'web'..."
  screen -dmS web bash -ic "cd \"$APP_DIR\" && $CMD; exec bash"
fi

echo "=== $(date) done ==="
