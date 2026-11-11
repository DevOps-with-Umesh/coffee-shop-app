#!/usr/bin/env bash
# 🎬 AUTOMATED DEMO FOR SCREEN RECORDING
#
# Runs the whole video flow by itself: types commands on screen, opens and refreshes
# the browser, crashes the app, starts Claude Code, waits for the site to come back.
#
# The only things YOU do while recording:
#   1. Press Enter once to start (after you start the screen recording)
#   2. In manual mode: press Enter on each Claude permission question (option 1 = Yes)
#   3. When Claude has finished: type /exit and press Enter (two times in the video)
#
# Usage (from the coffee-shop-app folder):
#   ./scripts/demo.sh
# Options:
#   BROWSER_APP="Safari" ./scripts/demo.sh   (default: Google Chrome)
#   TYPE_SPEED=0.05 ./scripts/demo.sh        (slower typing; default 0.035 seconds per letter)
#   SCENE_PAUSE=5 ./scripts/demo.sh          (longer title cards; default 4 seconds)

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

URL="http://localhost:8888"
NS="coffee"
BROWSER_APP="${BROWSER_APP:-Google Chrome}"
TYPE_SPEED="${TYPE_SPEED:-0.035}"
SCENE_PAUSE="${SCENE_PAUSE:-4}"

PROMPT_1='Our DevOps Coffee website at localhost:8888 went down right after the team deployed v2. It runs in the coffee namespace. Find out why it is down and fix it.'
PROMPT_2='The DevOps Coffee website is down again after another deploy. Namespace: coffee. Investigate and fix it.'

B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; X=$'\033[0m'
LINE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ---------- helpers ----------
banner() {   # big title card between scenes (easy to find when editing)
  clear; echo; echo
  echo "  ${C}${B}${LINE}${X}"
  echo "  ${B}$1${X}"
  if [ -n "${2:-}" ]; then echo "  ${D}$2${X}"; fi
  echo "  ${C}${B}${LINE}${X}"
  echo
  sleep "$SCENE_PAUSE"
}

type_cmd() { # "types" a command on screen like a human
  local cmd="$1" i
  printf '%s' "${G}➜${X} ${B}"
  for (( i=0; i<${#cmd}; i++ )); do
    printf '%s' "${cmd:$i:1}"
    sleep "$TYPE_SPEED"
  done
  printf '%s\n' "${X}"
  sleep 0.5
}

run() {      # type a command, run it, pause
  type_cmd "$1"
  eval "$1"
  echo
  sleep "${2:-2}"
}

note() { echo "  ${Y}💬 $1${X}"; echo; sleep "${2:-2}"; }

site_is_up() { [ "$(curl -s -o /dev/null -m 3 -w '%{http_code}' "$URL")" = "200" ]; }

wait_site_up() {
  local i
  for i in $(seq 1 90); do site_is_up && return 0; sleep 2; done
  echo "  ${R}Site did not come back within 3 minutes.${X}"; return 1
}

wait_site_down() {
  local i
  for i in $(seq 1 45); do site_is_up || return 0; sleep 2; done
  return 1
}

wait_pod_status() { # $1 = statuses to wait for, e.g. "CrashLoopBackOff|Error"
  local i
  for i in $(seq 1 45); do
    kubectl get pods -n "$NS" --no-headers 2>/dev/null | grep -Eq "$1" && return 0
    sleep 2
  done
  return 1
}

browser_open() { open -a "$BROWSER_APP" "$URL"; }

browser_refresh() {
  case "$BROWSER_APP" in
    "Google Chrome") osascript -e 'tell application "Google Chrome" to reload active tab of front window' >/dev/null 2>&1 ;;
    "Safari")        osascript -e "tell application \"Safari\" to set URL of front document to \"$URL\"" >/dev/null 2>&1 ;;
    *)               open -a "$BROWSER_APP" "$URL" ;;
  esac
  sleep 2
}

TUNNEL_PID=""
start_tunnel() { # localhost:8888 → the app (reconnects when pods are replaced)
  if pgrep -f "port-forward svc/coffee-shop 8888:80" >/dev/null; then return; fi
  ( while true; do
      kubectl port-forward svc/coffee-shop 8888:80 -n "$NS" >/dev/null 2>&1
      sleep 1
    done ) &
  TUNNEL_PID=$!
  disown "$TUNNEL_PID" 2>/dev/null   # no "Terminated" message on exit
}

cleanup() {
  if [ -n "$TUNNEL_PID" ]; then
    kill "$TUNNEL_PID" 2>/dev/null
    pkill -f "port-forward svc/coffee-shop 8888:80" 2>/dev/null
  fi
}
trap cleanup EXIT

# ---------- preflight (not part of the video) ----------
clear
echo "${B}🎬 DevOps Coffee: automated demo${X}"
echo
if [ "$(kubectl config current-context 2>/dev/null)" != "docker-desktop" ]; then
  echo "${R}kubectl is not on the docker-desktop context. Run:  kubectl config use-context docker-desktop${X}"
  exit 1
fi
command -v claude >/dev/null || { echo "${R}Claude Code not found. Install it first (see README).${X}"; exit 1; }

echo "⏳ Resetting the app to a healthy v1 (about 30 seconds)..."
./scripts/reset.sh >/dev/null 2>&1 || { echo "${R}Reset failed. Run ./scripts/reset.sh to see why.${X}"; exit 1; }
start_tunnel
wait_site_up || exit 1
browser_open
sleep 2
echo
echo "${G}✅ Ready.${X} Arrange your screen: Terminal on the LEFT, ${BROWSER_APP} on the RIGHT."
echo
echo "   Then START YOUR SCREEN RECORDING (Cmd + Shift + 5) and press ${B}Enter${X} here."
read -r _
for n in 3 2 1; do clear; echo; echo "   ${B}Starting in ${n}...${X}"; sleep 1; done

# ---------- SCENE 1: the app is live ----------
banner "SCENE 1 · The app is live" "DevOps Coffee v1 running on Kubernetes"
run "kubectl get pods -n coffee"
run "kubectl get svc -n coffee"
browser_refresh
note "Site is online at $URL: Version v1" 4

# ---------- SCENE 2: incident #1 ----------
banner "SCENE 2 · Incident #1: a teammate deploys v2" "\"Just a small config change…\""
run "./scripts/glitch-1-bad-config.sh" 1
note "Waiting for the new version to roll out…" 1
wait_pod_status "CrashLoopBackOff|Error"
wait_site_down
browser_refresh
run "kubectl get pods -n coffee"
note "🔥 THE SITE IS DOWN. Pod is crashing." 4

# ---------- SCENE 3: Claude, manual mode ----------
banner "SCENE 3 · Claude Code fixes it (manual mode)" "Claude must ask before every command"
run "cat claude-workspace/CLAUDE.md" 5
type_cmd "cd claude-workspace && claude --permission-mode default \"$PROMPT_1\""
( cd claude-workspace && claude --permission-mode default "$PROMPT_1" )

# ---------- SCENE 4: back online ----------
banner "SCENE 4 · Is the site back?"
note "Waiting for the fixed version to start…" 1
wait_site_up
sleep 2
browser_refresh
run "kubectl get pods -n coffee"
note "✅ ONLINE AGAIN, now running v2" 5

# ---------- SCENE 5: incident #2 ----------
banner "SCENE 5 · Incident #2: another bad deploy" "\"Upgrading the base image, quick change…\""
run "./scripts/glitch-2-bad-image.sh" 1
note "Waiting for the new version to roll out…" 1
wait_pod_status "ImagePullBackOff|ErrImagePull"
wait_site_down
browser_refresh
run "kubectl get pods -n coffee"
note "🔥 DOWN AGAIN." 4

# ---------- SCENE 6: Claude, auto mode ----------
banner "SCENE 6 · Claude Code fixes it (auto mode)" "Claude checks each command for risk and runs the safe ones by itself"
type_cmd "cd claude-workspace && claude --permission-mode auto \"$PROMPT_2\""
( cd claude-workspace && claude --permission-mode auto "$PROMPT_2" )

# ---------- SCENE 7: back online ----------
banner "SCENE 7 · Is the site back?"
wait_site_up
sleep 2
browser_refresh
run "kubectl get pods -n coffee"
note "✅ ONLINE AGAIN" 4

# ---------- SCENE 8: wrap-up ----------
banner "SCENE 8 · Manual mode vs Auto mode"
cat <<EOF
   ${B}⏸  MANUAL MODE${X}   claude --permission-mode default
       You approve every command
       → production, learning, anything risky

   ${B}⏵⏵ AUTO MODE${X}     claude --permission-mode auto
       Claude checks each command for risk and runs the safe ones
       → local labs, dev clusters, routine work

   Switch any time with ${B}Shift + Tab${X}

EOF
sleep 8
banner "Thanks for watching!  ☕  DevOps with Umesh" "App + scripts: link in the description"
sleep 3
echo "   ${D}(You can stop the screen recording now.)${X}"
