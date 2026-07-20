#!/usr/bin/env zsh

emulate -L zsh
setopt ERR_EXIT PIPE_FAIL

if ! print -r -- "${IMAGE_NAME:-}" |
  grep -Eq '^localhost:5000/[a-z0-9][a-z0-9._/-]*:[A-Fa-f0-9]{40}$'; then
  print -u2 -r -- "An immutable 40-character commit tag is required: ${IMAGE_NAME:-missing}"
  exit 1
fi

if [[ "${USE_MAC:-false}" != 'true' ]]; then
  print -r -- "Pushing $IMAGE_NAME to the first-node local registry."
  docker push "$IMAGE_NAME"
else
  if ! print -r -- "${FIRST_HOST:-}" |
    grep -Eq '^([a-z_][a-z0-9_-]*@)?[A-Za-z0-9][A-Za-z0-9.-]*$'; then
    print -u2 -r -- 'FIRST_HOST must be a hostname or user@hostname.'
    exit 1
  fi

  if ! print -r -- "${FIRST_USER:-}" |
    grep -Eq '^[a-z_][a-z0-9_-]*$'; then
    print -u2 -r -- 'FIRST_USER is invalid.'
    exit 1
  fi

  readonly first_target="$([[ "$FIRST_HOST" == *@* ]] && print -r -- "$FIRST_HOST" || print -r -- "${FIRST_USER}@${FIRST_HOST}")"
  readonly remote_publish_command="set -e; trap \"sudo -n docker image rm '$IMAGE_NAME' >/dev/null 2>&1 || true\" EXIT; gunzip | sudo -n docker load >/dev/null; sudo -n docker push '$IMAGE_NAME'"

  print -r -- "Transferring Mac-built image to the first-node registry: $IMAGE_NAME"
  docker save "$IMAGE_NAME" |
    gzip -1 |
    ssh \
      -o BatchMode=yes \
      -o StrictHostKeyChecking=yes \
      -o ServerAliveInterval=15 \
      "$first_target" \
      "zsh -c ${(qq)remote_publish_command}"
fi
