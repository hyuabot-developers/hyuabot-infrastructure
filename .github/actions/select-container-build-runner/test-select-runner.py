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


assert module.mac_status(
    [runner("Jeongin-MBP", "online", False, ["macOS", "container-build"])],
    "Jeongin-MBP",
    "container-build",
) == "online"
assert module.mac_status(
    [runner("Jeongin-MBP", "online", True, ["macOS", "container-build"])],
    "Jeongin-MBP",
    "container-build",
) == "online"
assert module.mac_status(
    [runner("Jeongin-MBP", "offline", False, ["macOS", "container-build"])],
    "Jeongin-MBP",
    "container-build",
) == "offline"

try:
    module.mac_status(
        [runner("Jeongin-MBP", "online", False, ["macOS"])],
        "Jeongin-MBP",
        "container-build",
    )
except RuntimeError as error:
    assert "missing required label" in str(error)
else:
    raise AssertionError("missing container-build label must fail selection")

try:
    module.mac_status([], "Jeongin-MBP", "container-build")
except RuntimeError as error:
    assert "was not found" in str(error)
else:
    raise AssertionError("missing Mac runner must fail selection")

print("SELECT_CONTAINER_BUILD_RUNNER_TEST_OK")
