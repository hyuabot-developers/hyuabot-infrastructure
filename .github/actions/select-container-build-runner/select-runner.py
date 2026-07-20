#!/usr/bin/env python3

import json
import os
import urllib.request


ORACLE_RUNNER = ["self-hosted", "ARM64", "Linux", "1st"]
MAC_RUNNER = ["self-hosted", "ARM64", "macOS", "container-build"]


def mac_status(
    runners: list[dict[str, object]], runner_name: str, required_label: str
) -> str:
    for runner in runners:
        if runner.get("name") != runner_name:
            continue
        labels = {
            label.get("name")
            for label in runner.get("labels", [])
            if isinstance(label, dict)
        }
        if required_label not in labels:
            raise RuntimeError(
                f"{runner_name} is missing required label {required_label}"
            )
        status = runner.get("status")
        if status not in {"online", "offline"}:
            raise RuntimeError(f"{runner_name} has unexpected status {status!r}")
        return status
    raise RuntimeError(f"{runner_name} was not found")


def append_output(name: str, value: str) -> None:
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        output.write(f"{name}={value}\n")


def main() -> None:
    token = os.environ.get("RUNNER_ADMIN_TOKEN", "")
    runner_name = os.environ.get("MAC_RUNNER_NAME", "Jeongin-MBP")
    required_label = os.environ.get("MAC_REQUIRED_LABEL", "container-build")

    if not token:
        raise RuntimeError("A token that can inspect organization runners is required")

    owner = os.environ["GITHUB_REPOSITORY_OWNER"]
    api_url = os.environ.get("GITHUB_API_URL", "https://api.github.com")
    request = urllib.request.Request(
        f"{api_url}/orgs/{owner}/actions/runners?per_page=100",
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        runners = json.load(response).get("runners", [])

    status = mac_status(runners, runner_name, required_label)
    use_mac = status == "online"

    selected_runner = MAC_RUNNER if use_mac else ORACLE_RUNNER
    append_output("runner", json.dumps(selected_runner, separators=(",", ":")))
    append_output("use-mac", str(use_mac).lower())
    if use_mac:
        print("Selected container build runner: MacBook (online; queue if busy)")
    else:
        print("Selected container build runner: first node (MacBook is offline)")


if __name__ == "__main__":
    main()
