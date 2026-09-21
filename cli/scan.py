#!/usr/bin/env python3
"""Love.css HTML scanner.

Scans HTML files in a directory, extracts tags and classes,
and reports which Love.css modules are required, installed, or missing.

It never traverses outside the given directory and never follows symlinks.
"""

import argparse
import json
import os
import re
import sys

EXCLUDE_DIRS = {
    ".git", "node_modules", "venv", ".venv", "env", "dist", "build",
    ".cache", "__pycache__", ".idea", ".vscode", "vendor", "assets",
}

SCAN_EXTENSIONS = {".html", ".htm"}

TAG_RE = re.compile(r"<\s*([a-zA-Z][a-zA-Z0-9-]*)")
CLASS_RE = re.compile(r'class\s*=\s*["\']([^"\']+)["\']')


def iter_html_files(root):
    """Yield HTML file paths under root, excluding known directories."""
    root = os.path.abspath(root)
    for dirpath, dirnames, filenames in os.walk(root, topdown=True, followlinks=False):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
        for name in filenames:
            ext = os.path.splitext(name)[1].lower()
            if ext in SCAN_EXTENSIONS:
                yield os.path.join(dirpath, name)


def extract_tags_and_classes(path):
    """Return (tags, classes) found in one HTML file."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except OSError:
        return set(), set()

    tags = {m.group(1).lower() for m in TAG_RE.finditer(content)}
    classes = set()
    for m in CLASS_RE.finditer(content):
        for cls in m.group(1).split():
            classes.add(cls)
    return tags, classes


def load_registry(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def build_lookup(registry):
    """Map tag -> module and class -> module."""
    tag_to_module = {}
    class_to_module = {}
    for module in registry.get("modules", []):
        name = module["name"]
        for tag in module.get("tags", []):
            tag_to_module.setdefault(tag.lower(), name)
        for cls in module.get("classes", []):
            class_to_module.setdefault(cls.lstrip("."), name)
    return tag_to_module, class_to_module


def installed_modules(css_dir):
    """Return set of installed module names from the project css directory."""
    if not os.path.isdir(css_dir):
        return set()
    result = set()
    for name in os.listdir(css_dir):
        if name.startswith("love.") and name.endswith(".css"):
            mod = name[len("love."):-len(".css")]
            if mod != "overrides":
                result.add(mod)
    return result


def main():
    parser = argparse.ArgumentParser(description="Love.css HTML scanner")
    parser.add_argument("--dir", default=os.getcwd(), help="Directory to scan")
    parser.add_argument("--registry", required=True, help="Path to modules.json")
    parser.add_argument("--css-dir", default=None, help="Project css directory")
    args = parser.parse_args()

    scan_dir = os.path.abspath(args.dir)
    if not os.path.isdir(scan_dir):
        print(f"love check: directory not found: {scan_dir}", file=sys.stderr)
        sys.exit(1)

    registry = load_registry(args.registry)
    tag_to_module, class_to_module = build_lookup(registry)
    css_dir = args.css_dir or os.path.join(scan_dir, "css")
    installed = installed_modules(css_dir)

    all_required = set()
    file_reports = []

    for html_path in iter_html_files(scan_dir):
        tags, classes = extract_tags_and_classes(html_path)
        required = set()
        for tag in tags:
            if tag in tag_to_module:
                required.add(tag_to_module[tag])
        for cls in classes:
            if cls in class_to_module:
                required.add(class_to_module[cls])
        all_required |= required
        rel = os.path.relpath(html_path, scan_dir)
        file_reports.append((rel, sorted(tags), sorted(required)))

    print("=== Love.css check ===")
    print(f"Scanned: {scan_dir}")
    print(f"HTML files: {len(file_reports)}")
    print("")

    if not file_reports:
        print("No HTML files found in the target directory.")
        print("Make sure you run this command from the project root.")
        return

    for rel, tags, required in file_reports:
        print(f"--- {rel} ---")
        if tags:
            print("  Tags: " + ", ".join(tags[:20]) + ("..." if len(tags) > 20 else ""))
        if required:
            print("  Modules: " + ", ".join(required))
        else:
            print("  Modules: none recognized")
        print("")

    print("=== Module status ===")
    for module in sorted(all_required):
        if module in installed:
            print(f"+ love.{module}")
        else:
            print(f"! love.{module}  (required but not installed)")
    for module in sorted(installed - all_required):
        print(f"- love.{module}  (installed but not used)")

    missing = all_required - installed
    if missing:
        print("")
        print("Install missing modules with:")
        for module in sorted(missing):
            print(f"  love add {module}")


if __name__ == "__main__":
    main()
