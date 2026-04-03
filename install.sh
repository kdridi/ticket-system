#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/kdridi/ticket-system/main"
SYSTEM_DIR=".tickets"
TICKETS_DIR="tickets"

echo "=== Ticket System - Installing ==="

# Download system files into .tickets/
mkdir -p "${SYSTEM_DIR}"
for file in config.yml TEMPLATE.md; do
  curl -sSLf "${REPO_RAW}/system/${file}" -o "${SYSTEM_DIR}/${file}"
  echo "  ${SYSTEM_DIR}/${file}"
done

# Create ticket directories
for dir in backlog planned ongoing completed rejected; do
  mkdir -p "${TICKETS_DIR}/${dir}"
  touch "${TICKETS_DIR}/${dir}/.gitkeep"
done

echo ""
echo "=== Done ==="
echo "System files: ./${SYSTEM_DIR}/"
echo "Tickets:      ./${TICKETS_DIR}/"
echo ""
echo "To uninstall: rm -rf ${SYSTEM_DIR}"
