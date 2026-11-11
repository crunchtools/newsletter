#!/usr/bin/env bash
# Boot gate: the image starts with a minimal config and answers HTTP on 8000.
# Usage: IMAGE=<ref> tests/image/boot-gate.sh   (or pass the image as $1)
set -euo pipefail
IMAGE="${1:-${IMAGE:?set IMAGE or pass the image as the first argument}}"
HERE="$(cd "$(dirname "$0")" && pwd)"
NAME="ktn-gate-$$"
cleanup() { podman rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

podman run -d --name "$NAME" -p 127.0.0.1::8000 \
  -v "$HERE/configuration.mjs:/config/configuration.mjs:ro,Z" "$IMAGE" >/dev/null
PORT="$(podman port "$NAME" 8000/tcp | head -n1 | sed 's/.*://')"

code=000
for _ in $(seq 1 60); do
  [ "$(podman inspect -f '{{.State.Running}}' "$NAME")" = true ] || {
    echo "container exited" >&2; podman logs "$NAME" >&2; exit 1; }
  code="$(curl -s -o /dev/null -w '%{http_code}' -H 'Host: localhost:8000' \
    "http://127.0.0.1:$PORT/" || true)"
  [ "$code" = 200 ] && { echo "boot gate: HTTP 200 on :8000"; exit 0; }
  sleep 2
done
echo "boot gate failed: last HTTP code $code" >&2
podman logs "$NAME" >&2
exit 1
