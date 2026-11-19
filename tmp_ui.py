import re
import subprocess
import sys
from pathlib import Path

adb = ["adb", "-s", "emulator-5554"]


def dump():
    subprocess.check_call(adb + ["shell", "uiautomator", "dump", "/sdcard/uidump.xml"], stdout=subprocess.DEVNULL)
    xml = subprocess.check_output(adb + ["shell", "cat", "/sdcard/uidump.xml"], text=True, encoding="utf-8", errors="replace")
    nodes = re.findall(r'<node[^>]*text="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', xml)
    # attributes order varies; parse more loosely
    parts = re.findall(r"<node ([^>]*)/>", xml)
    rows = []
    for attrs in parts:
        text = re.search(r'text="([^"]*)"', attrs)
        desc = re.search(r'content-desc="([^"]*)"', attrs)
        bounds = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', attrs)
        click = re.search(r'clickable="(true|false)"', attrs)
        if not bounds:
            continue
        label = (text.group(1) if text else "") or (desc.group(1) if desc else "")
        if not label:
            continue
        x1, y1, x2, y2 = map(int, bounds.groups())
        rows.append((label, (x1 + x2) // 2, (y1 + y2) // 2, click.group(1) if click else "?"))
    return rows


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "tap":
        x, y = sys.argv[2], sys.argv[3]
        subprocess.check_call(adb + ["shell", "input", "tap", x, y])
    else:
        for label, x, y, click in dump():
            print(f"{click:5} {x:4},{y:4} {label}")
