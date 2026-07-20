#!/usr/bin/env python3

import importlib.util
from pathlib import Path


module_path = Path(__file__).with_name("select-runner.py")
spec = importlib.util.spec_from_file_location("select_runner", module_path)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def runner(name: str, status: str, busy: bool, labels: list[str]) -> dict:
    return {
        "name": name,
        "status": status,
        "busy": busy,
        "labels": [{"name": label} for label in labels],
    }


assert module.mac_is_available(
    [runner("Jeongin-MBP", "online", False, ["macOS", "container-build"])],
    "Jeongin-MBP",
    "container-build",
)
assert not module.mac_is_available(
    [runner("Jeongin-MBP", "online", False, ["macOS"])],
    "Jeongin-MBP",
    "container-build",
)
assert not module.mac_is_available(
    [runner("Jeongin-MBP", "online", True, ["macOS", "container-build"])],
    "Jeongin-MBP",
    "container-build",
)

print("SELECT_CONTAINER_BUILD_RUNNER_TEST_OK")
