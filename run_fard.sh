#!/usr/bin/env bash
set -u
FARDRUN="${FARDRUN:-}"
if [ -z "$FARDRUN" ]; then
  echo "FARDRUN is empty" 1>&2
  exit 2
fi
exec "$FARDRUN" "$@"
