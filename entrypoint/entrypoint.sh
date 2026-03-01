#!/usr/bin/env bash
set -e

COMMAND=$1
shift || true
ESC="$(printf '\033')"

NC="${ESC}[0m"
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"


case "$COMMAND" in
  intro)
    printf "%b" "${GREEN}"
    cat /ufo-maketools/intro "$@"
    printf "%b" "${NC}"
    ;;
  init|install)
    printf "%b" "${GREEN}"
    cat /ufo-maketools/intro "$@"
    printf "%b" "${NC}"
    /ufo-maketools/commands/install.sh "$@"
    ;;
  update)
    printf "%b" "${GREEN}"
    cat /ufo-maketools/intro "$@"
    printf "%b" "${NC}"
    /ufo-maketools/commands/update.sh "$@"
    ;;
  version)
    printf "%b" "${GREEN}"
    cat /ufo-maketools/intro "$@"
    printf "%b" "${NC}${YELLOW}"
    cat /ufo-maketools/VERSION
    printf "%b" "${NC}"
    ;;
  *)
    echo "Unknown command: $COMMAND"
    exit 1
    ;;
esac