#!/usr/bin/env python3

import os
import subprocess

# TODO: handle ctrl-c during check run and during this script execution

welcome_message = """Welcome to Pre-HAP Validation!

This tool runs multiple checks verifying that the environment is ready to start the \
Hardware Automation Package (HAP) phase.
"""


def print_summary(checks):
    print("\nTest results summary:")
    for check in checks:
        print(f"{check['filename'] + ' ':.<50} {check['result']}")


def run_check(check) -> str:
    check_path = os.path.join(check["path"], check["filename"])

    try:
        subprocess.check_call(check_path)
    except subprocess.CalledProcessError as e:
        return "Failed"

    return "Success"


def create_desktop_shortcut():
    # Copy launcher to the desktop if it does not exist yet
    if not os.path.isfile("/home/ubuntu/Desktop/pre-hap-validation-launcher.desktop"):
        subprocess.run(
            [
                "cp",
                "/etc/xdg/autostart/pre-hap-validation-launcher.desktop",
                "/home/ubuntu/Desktop",
            ]
        )
        subprocess.run(
            ["chown", "ubuntu:ubuntu", "/home/ubuntu/Desktop/pre-hap-validation-launcher.desktop"]
        )
        subprocess.run(["chmod", "+x", "/home/ubuntu/Desktop/pre-hap-validation-launcher.desktop"])

        # Trust the launcher
        subprocess.run(
            [
                "sudo",
                "-H",
                "-u",
                "ubuntu",
                "bash",
                "-c",
                "dbus-launch gio set /home/ubuntu/Desktop/pre-hap-validation-launcher.desktop 'metadata::trusted' yes &> /dev/null",
            ]
        )


def main():
    create_desktop_shortcut()

    print(welcome_message)

    #
    # Create the list of checks to be executed
    #

    checks_enabled_path = "checks-enabled"

    checks = []

    # Search path for executable files
    for root, directories, files in os.walk(checks_enabled_path):
        for file in files:

            # Check if the file is executable
            executable = os.access(os.path.join(root, file), os.X_OK)

            # Add the file to the list only if it is executable
            if executable:
                item = {"path": root, "filename": file, "result": "Not run"}
                checks.append(item)

    # Sort by filename
    checks_sorted = sorted(checks, key=lambda k: k["filename"])

    #
    # List checks to be run
    #

    if 0 == len(checks_sorted):
        print("No checks found in 'checks-enabled' directory. Exiting.")
        exit(1)

    print("The following checks will be run:\n")

    for check in checks_sorted:
        print(f"  {check['filename']}")

    #
    # Run checks
    #

    for check in checks_sorted:
        print(f"\nRun check '{check['filename']}'?")

        valid_answers = ["r", "s", "q", ""]
        answer = "invalid initial answer"

        while answer not in valid_answers:
            answer = input("(R)un, (s)kip, (q)uit: ").lower()

        if answer in ["", "r"]:
            print(f"Running check '{check['filename']}'...\n")
            check["result"] = run_check(check)
        elif answer == "s":
            print(f"Skipping check '{check['filename']}'.")
            check["result"] = "Skipped"
        elif answer == "q":
            print(f"Quitting.")
            break
        else:
            print(f"ERROR: got unexpected answer, exiting.")
            break

    # Print test results
    print_summary(checks_sorted)


if __name__ == "__main__":
    main()