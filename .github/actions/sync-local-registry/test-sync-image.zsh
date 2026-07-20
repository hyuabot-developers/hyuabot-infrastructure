#!/usr/bin/env zsh

emulate -L zsh
setopt ERR_EXIT PIPE_FAIL

readonly action_dir="${0:A:h}"
readonly test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT

readonly manifest='{"config":{"digest":"sha256:config"},"layers":[{"digest":"sha256:layer-1"},{"digest":"sha256:layer-2"}]}'
readonly expected_identity="$(
  print -rn -- "$manifest" |
  python3 -c '
import hashlib
import json
import sys

manifest = json.load(sys.stdin)
parts = [
    manifest["config"]["digest"],
    *(layer["digest"] for layer in manifest["layers"]),
]
print(hashlib.sha256("\n".join(parts).encode()).hexdigest())
'
)"

function docker() {
  case "$1" in
    pull)
      print -r -- "$2"
      ;;
    save)
      print -rn -- 'mock-image-archive'
      ;;
    image)
      if [[ "$2" != 'rm' ]]; then
        print -u2 -r -- "Unexpected docker image command: $*"
        return 1
      fi
      print -r -- "$3" >> "$test_dir/removed-images"
      ;;
    *)
      print -u2 -r -- "Unexpected docker command: $*"
      return 1
      ;;
  esac
}

function gzip() {
  command cat
}

function curl() {
  print -rn -- "$manifest"
}

function ssh() {
  if [[ "$*" == *"REPOSITORY="* ]]; then
    command cat >/dev/null
    print -r -- "$expected_identity"
  elif [[ "$*" == *"gunzip"* ]]; then
    command cat >/dev/null
  fi
}

IMAGE_NAME='localhost:5000/example/image:latest' \
WORKER_HOST='worker.example.com' \
WORKER_USER='ubuntu' \
GITHUB_OUTPUT="$test_dir/github-output" \
  source "$action_dir/sync-image.zsh"

grep -qxF \
  "content-identity=$expected_identity" \
  "$test_dir/github-output"

IMAGE_NAME='localhost:5000/example/image:latest' \
WORKER_HOST='worker.example.com' \
WORKER_USER='ubuntu' \
  source "$action_dir/cleanup-image.zsh"

grep -qxF \
  'localhost:5000/example/image:latest' \
  "$test_dir/removed-images"

if (
  IMAGE_NAME='localhost:5000/example/image:latest;uname' \
  WORKER_HOST='worker.example.com' \
  WORKER_USER='ubuntu' \
    source "$action_dir/sync-image.zsh"
) 2>/dev/null; then
  print -u2 -r -- 'Unsafe image input was accepted.'
  exit 1
fi

print -r -- 'SYNC_LOCAL_REGISTRY_ACTION_TEST_OK'
