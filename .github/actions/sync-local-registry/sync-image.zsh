#!/usr/bin/env zsh

emulate -L zsh
setopt ERR_EXIT PIPE_FAIL

if [[ -z "${IMAGE_NAME:-}" ]]; then
  print -u2 -r -- 'IMAGE_NAME is required.'
  exit 1
fi

if ! print -r -- "$IMAGE_NAME" |
  grep -Eq '^localhost:5000/[a-z0-9][a-z0-9._/-]*:[A-Za-z0-9_][A-Za-z0-9._-]*$'; then
  print -u2 -r -- "Unsupported image reference: $IMAGE_NAME"
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

readonly image_path="${IMAGE_NAME#localhost:5000/}"
readonly repository="${image_path%:*}"
readonly image_tag="${image_path##*:}"
readonly worker_target="${WORKER_USER}@${WORKER_HOST}"
readonly registry_accept='application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json'

function manifest_identity() {
  local manifest_url="$1"

  curl -fsSL \
    -H "Accept: $registry_accept" \
    "$manifest_url" |
    python3 -c '
import hashlib
import json
import sys

manifest = json.load(sys.stdin)
try:
    parts = [
        manifest["config"]["digest"],
        *(layer["digest"] for layer in manifest["layers"]),
    ]
except (KeyError, TypeError) as error:
    raise SystemExit("A single-platform image manifest is required") from error

print(hashlib.sha256("\n".join(parts).encode()).hexdigest())
'
}

print -r -- "Pulling $IMAGE_NAME from the first-node registry."
docker pull "$IMAGE_NAME"

readonly remote_check_command='curl -fsS http://127.0.0.1:5000/v2/ >/dev/null && sudo -n docker version >/dev/null'

print -r -- "Checking SSH and the worker-local registry on $worker_target."
ssh \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=yes \
  -o ConnectTimeout=15 \
  "$worker_target" \
  "zsh -c ${(qq)remote_check_command}"

readonly remote_sync_command="gunzip | sudo -n docker load >/dev/null && sudo -n docker push '$IMAGE_NAME'"

print -r -- "Copying $IMAGE_NAME to the worker-local registry."
docker save "$IMAGE_NAME" |
  gzip -1 |
  ssh \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=yes \
    -o ServerAliveInterval=15 \
    "$worker_target" \
    "zsh -c ${(qq)remote_sync_command}"

readonly first_identity="$(
  manifest_identity \
    "http://127.0.0.1:5000/v2/${repository}/manifests/${image_tag}"
)"

readonly worker_identity="$(
  ssh \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=yes \
    -o ConnectTimeout=15 \
    "$worker_target" \
    "REPOSITORY='$repository' IMAGE_TAG='$image_tag' zsh -s" <<'REMOTE_ZSH'
registry_accept='application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json'

curl -fsSL \
  -H "Accept: $registry_accept" \
  "http://127.0.0.1:5000/v2/${REPOSITORY}/manifests/${IMAGE_TAG}" |
  python3 -c '
import hashlib
import json
import sys

manifest = json.load(sys.stdin)
try:
    parts = [
        manifest["config"]["digest"],
        *(layer["digest"] for layer in manifest["layers"]),
    ]
except (KeyError, TypeError) as error:
    raise SystemExit("A single-platform image manifest is required") from error

print(hashlib.sha256("\n".join(parts).encode()).hexdigest())
'
REMOTE_ZSH
)"

if [[ -z "$first_identity" || "$first_identity" != "$worker_identity" ]]; then
  print -u2 -r -- "First-node content identity: ${first_identity:-missing}"
  print -u2 -r -- "Worker content identity: ${worker_identity:-missing}"
  print -u2 -r -- 'Registry image content does not match.'
  exit 1
fi

print -r -- "Verified image content identity: $first_identity"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  print -r -- "content-identity=$first_identity" >> "$GITHUB_OUTPUT"
fi
