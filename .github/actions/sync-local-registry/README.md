# Sync local registry image

This composite action copies one tagged image from the registry bound to the first K3s node to the registry bound to the worker node. The worker registry remains loopback-only; image transfer uses authenticated SSH.

After the worker push, the action compares a content identity derived from the image config digest and ordered layer digests. Registry manifest digests are intentionally not compared because different Docker versions can preserve identical image content while converting between OCI and Docker schema v2 manifests.

The final step removes the tagged image from both nodes' Docker stores. Registry manifests and layers remain available for deployment and rollback.

## Runner prerequisites

- The job runs on the first node after the image has been pushed to `localhost:5000`.
- `zsh`, Docker, `curl`, `gzip`, Python 3, and SSH are available.
- The worker SSH host key already exists in the runner user's `known_hosts` file.
- SSH public-key authentication succeeds without interaction.
- The worker user can run Docker through passwordless `sudo -n`.
- The worker registry responds on `http://127.0.0.1:5000/v2/`.

## Usage

Pin the action to a full commit SHA when calling it from another repository:

```yaml
- name: Sync image to worker registry
  uses: hyuabot-developers/hyuabot-infrastructure/.github/actions/sync-local-registry@<full-commit-sha>
  with:
    image: ${{ env.IMAGE_NAME }}
```
