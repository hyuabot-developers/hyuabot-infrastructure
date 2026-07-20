# Publish to first-node registry

This action publishes a commit-SHA-tagged image to the registry bound to the first K3s node.

- A first-node build pushes directly to `localhost:5000`.
- A Mac build streams `docker save` over authenticated SSH, then loads and pushes the image on the first node.
- The build runner image copy is removed after publishing.
- A transferred first-node Docker image is removed after its registry push.

The registry remains loopback-only in both paths.
