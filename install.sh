#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/kdridi/ticket-system/main"
SYSTEM_DIR=".tickets"
TICKETS_DIR="tickets"
COMMANDS_DIR=".claude/commands/tickets"

echo "=== Ticket System - Installing ==="

# Download system files into .tickets/
mkdir -p "${SYSTEM_DIR}"
for file in config.yml TEMPLATE.md; do
  curl -sSLf "${REPO_RAW}/system/${file}" -o "${SYSTEM_DIR}/${file}"
  echo "  ${SYSTEM_DIR}/${file}"
done

# Prompt for ticket ID prefix (< /dev/tty needed for curl | bash)
read -rp "Ticket ID prefix [PROJ]: " PREFIX < /dev/tty
PREFIX="${PREFIX:-PROJ}"
cat > "${SYSTEM_DIR}/config.yml" <<CONF
prefix: "${PREFIX}"
digits: 3
tickets_dir: "tickets"
CONF
echo "  Prefix set to: ${PREFIX}"

# Download slash commands into .claude/commands/tickets/
mkdir -p "${COMMANDS_DIR}"
for file in create.md; do
  curl -sSLf "${REPO_RAW}/system/commands/tickets/${file}" -o "${COMMANDS_DIR}/${file}"
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
