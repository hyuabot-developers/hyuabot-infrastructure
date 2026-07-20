#!/usr/bin/env python3

import json
import os
import urllib.request


ORACLE_RUNNER = ["self-hosted", "ARM64", "Linux", "1st"]
MAC_RUNNER = ["self-hosted", "ARM64", "macOS", "container-build"]


def mac_is_available(
    runners: list[dict[str, object]], runner_name: str, required_label: str
) -> bool:
    for runner in runners:
        if runner.get("name") != runner_name:
            continue
        labels = {
            label.get("name")
            for label in runner.get("labels", [])
            if isinstance(label, dict)
        }
        return (
            runner.get("status") == "online"
            and runner.get("busy") is False
            and required_label in labels
        )
    return False


def append_output(name: str, value: str) -> None:
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        output.write(f"{name}={value}\n")


def main() -> None:
    use_mac = False
    token = os.environ.get("RUNNER_ADMIN_TOKEN", "")
    mac_enabled = os.environ.get("MAC_ENABLED", "false").lower() == "true"
    runner_name = os.environ.get("MAC_RUNNER_NAME", "Jeongin-MBP")
    required_label = os.environ.get("MAC_REQUIRED_LABEL", "container-build")

    if mac_enabled and token:
        try:
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
            use_mac = mac_is_available(runners, runner_name, required_label)
        except Exception as error:  # The production fallback must remain available.
            print(f"Could not inspect {runner_name}; using the first node: {error}")

    selected_runner = MAC_RUNNER if use_mac else ORACLE_RUNNER
    append_output("runner", json.dumps(selected_runner, separators=(",", ":")))
    append_output("use-mac", str(use_mac).lower())
    print(f"Selected container build runner: {'MacBook' if use_mac else 'first node'}")


if __name__ == "__main__":
    main()
