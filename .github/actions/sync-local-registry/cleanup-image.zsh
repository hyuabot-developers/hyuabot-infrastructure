#!/usr/bin/env zsh

emulate -L zsh
setopt ERR_EXIT PIPE_FAIL

if ! print -r -- "${IMAGE_NAME:-}" |
  grep -Eq '^localhost:5000/[a-z0-9][a-z0-9._/-]*:[A-Za-z0-9_][A-Za-z0-9._-]*$'; then
  print -u2 -r -- "Unsupported image reference: ${IMAGE_NAME:-missing}"
  exit 1
fi

if ! print -r -- "${WORKER_HOST:-}" |
  grep -Eq '^[A-Za-z0-9][A-Za-z0-9.-]*$'; then
  print -u2 -r -- 'WORKER_HOST must be a hostname or IPv4 address.'
  exit 1
fi

if ! print -r -- "${WORKER_USER:-}" |
  grep -Eq '^[a-z_][a-z0-9_-]*$'; then
  print -u2 -r -- 'WORKER_USER is invalid.'
  exit 1
fi

readonly cleanup_worker_target="${WORKER_USER}@${WORKER_HOST}"
readonly remote_cleanup_command="sudo -n docker image rm '$IMAGE_NAME' >/dev/null 2>&1 || true"

print -r -- "Removing the Docker image copy from the first node: $IMAGE_NAME"
docker image rm "$IMAGE_NAME" >/dev/null 2>&1 || true

print -r -- "Removing the Docker image copy from the worker: $IMAGE_NAME"
if ! ssh \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=yes \
  -o ConnectTimeout=15 \
  "$cleanup_worker_target" \
  "zsh -c ${(qq)remote_cleanup_command}"; then
  print -u2 -r -- "Warning: could not remove $IMAGE_NAME from the worker Docker store."
fi
