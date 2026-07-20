# Select container build runner

This action selects `Jeongin-MBP` only when it is online, idle, has the `container-build` label, and the calling workflow has enabled Mac publishing. Otherwise it returns the first production node labels.

The `container-build` label is an explicit capability flag. An online Mac without a working Docker-compatible engine must not receive container builds.
