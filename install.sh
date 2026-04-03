#!/usr/bin/env bash
set -euo pipefail

SYSTEM_DIR=".tickets"
TICKETS_DIR="tickets"
COMMANDS_DIR=".claude/commands/tickets"

# Detect invocation mode: local (bash install.sh) vs remote (curl | bash)
if [ -f "$0" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  MODE="local"
else
  REPO_RAW="https://raw.githubusercontent.com/kdridi/ticket-system/main"
  MODE="remote"
fi

# Fetch a file: copy locally or download from GitHub
fetch() {
  local src="$1" dst="$2"
  if [ "$MODE" = "local" ]; then
    cp "${SCRIPT_DIR}/${src}" "$dst"
  else
    curl -sSLf "${REPO_RAW}/${src}" -o "$dst"
  fi
}

echo "=== Ticket System - Installing ==="

# Install system files into .tickets/
mkdir -p "${SYSTEM_DIR}"
for file in config.yml TEMPLATE.md; do
  fetch "system/${file}" "${SYSTEM_DIR}/${file}"
  echo "  ${SYSTEM_DIR}/${file}"
done

# Prompt for ticket ID prefix
# Local mode: read from stdin; remote (curl|bash): read from /dev/tty
if [ "$MODE" = "local" ]; then
  read -rp "Ticket ID prefix [PROJ]: " PREFIX
else
  read -rp "Ticket ID prefix [PROJ]: " PREFIX < /dev/tty
fi
PREFIX="${PREFIX:-PROJ}"
cat > "${SYSTEM_DIR}/config.yml" <<CONF
prefix: "${PREFIX}"
digits: 3
tickets_dir: "tickets"
CONF
echo "  Prefix set to: ${PREFIX}"

# Install slash commands into .claude/commands/tickets/
mkdir -p "${COMMANDS_DIR}"
for file in create.md; do
  fetch "system/commands/tickets/${file}" "${COMMANDS_DIR}/${file}"
  echo "  ${COMMANDS_DIR}/${file}"
done

# Create ticket directories
for dir in backlog planned ongoing completed rejected; do
  mkdir -p "${TICKETS_DIR}/${dir}"
  touch "${TICKETS_DIR}/${dir}/.gitkeep"
done

echo ""
echo "=== Done ==="
echo "System files: ./${SYSTEM_DIR}/"
echo "Commands:     ./${COMMANDS_DIR}/"
echo "Tickets:      ./${TICKETS_DIR}/"
echo ""
echo "To uninstall: rm -rf ${SYSTEM_DIR} ${COMMANDS_DIR}"
