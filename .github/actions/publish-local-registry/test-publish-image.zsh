#!/usr/bin/env zsh

emulate -L zsh
setopt ERR_EXIT PIPE_FAIL

readonly action_dir="${0:A:h}"
readonly test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
readonly image='localhost:5000/example/image:0123456789abcdef0123456789abcdef01234567'

function docker() {
  print -r -- "$*" >> "$test_dir/docker-calls"
  if [[ "$1" == 'save' ]]; then
    print -rn -- 'mock-image'
  fi
}

function gzip() {
  command cat
}

function ssh() {
  command cat >/dev/null
  print -r -- "$*" >> "$test_dir/ssh-calls"
}

(IMAGE_NAME="$image" USE_MAC='false' source "$action_dir/publish-image.zsh")
grep -qxF "push $image" "$test_dir/docker-calls"

(
  IMAGE_NAME="$image" \
  USE_MAC='true' \
  FIRST_HOST='oracle.example.com' \
  FIRST_USER='ubuntu' \
    source "$action_dir/publish-image.zsh"
)
grep -qxF "save $image" "$test_dir/docker-calls"
grep -qF 'ubuntu@oracle.example.com' "$test_dir/ssh-calls"

(
  IMAGE_NAME="$image" \
  USE_MAC='true' \
  FIRST_HOST='' \
  FIRST_USER='ubuntu' \
    source "$action_dir/publish-image.zsh"
)
grep -qF 'ubuntu@oracle.hyuabot.app' "$test_dir/ssh-calls"

if (
  IMAGE_NAME='localhost:5000/example/image:latest' \
  USE_MAC='false' \
    source "$action_dir/publish-image.zsh"
) 2>/dev/null; then
  print -u2 -r -- 'A mutable image tag was accepted.'
  exit 1
fi

print -r -- 'PUBLISH_LOCAL_REGISTRY_ACTION_TEST_OK'
