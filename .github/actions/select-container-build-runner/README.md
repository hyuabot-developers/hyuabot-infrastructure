# Select container build runner

This action selects `Jeongin-MBP` whenever it is online and has the `container-build` label. A busy Mac remains selected so the build waits in its runner queue. The first production node is returned only when GitHub explicitly reports the Mac as offline.

The `container-build` label is an explicit capability flag. An online Mac without a working Docker-compatible engine must not receive container builds.

Runner lookup failures, a missing token, a missing Mac runner, and a missing capability label fail the workflow instead of silently moving the build to production.
