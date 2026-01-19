#!/usr/bin/env bash
set -euo pipefail

############################################################
# Kill all anvil processes
############################################################

echo "Searching for anvil processes..."

# Find all anvil PIDs
ANVIL_PIDS=$(pgrep -f "anvil.*--fork-url" || true)

if [ -z "$ANVIL_PIDS" ]; then
  echo "No anvil processes found."
  exit 0
fi

echo "Found anvil processes:"
echo "$ANVIL_PIDS" | while read -r pid; do
  if [ -n "$pid" ]; then
    # Get process details
    ps -p "$pid" -o pid=,command= 2>/dev/null || true
  fi
done

echo
echo "Killing anvil processes..."

# Kill all anvil processes
echo "$ANVIL_PIDS" | while read -r pid; do
  if [ -n "$pid" ]; then
    kill "$pid" 2>/dev/null && echo "  Killed PID: $pid" || echo "  Failed to kill PID: $pid"
  fi
done

# Wait a moment for processes to terminate
sleep 1

# Force kill any remaining anvil processes
REMAINING_PIDS=$(pgrep -f "anvil.*--fork-url" || true)
if [ -n "$REMAINING_PIDS" ]; then
  echo
  echo "Force killing remaining anvil processes..."
  echo "$REMAINING_PIDS" | while read -r pid; do
    if [ -n "$pid" ]; then
      kill -9 "$pid" 2>/dev/null && echo "  Force killed PID: $pid" || true
    fi
  done
fi

echo
echo "Done. All anvil processes have been terminated."
