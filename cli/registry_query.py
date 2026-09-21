#!/usr/bin/env python3
"""Love.css registry query helper.

Provides JSON queries used by the POSIX shell CLI. Kept separate from
scan.py so that each script has a single responsibility.
"""

import json
import sys


def load(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def cmd_modules(registry_path):
    reg = load(registry_path)
    for module in reg.get("modules", []):
        print(module["name"])


def cmd_module_file(registry_path, name):
    reg = load(registry_path)
    for module in reg.get("modules", []):
        if module["name"] == name:
            print(module["file"])
            return
    sys.exit(1)


def cmd_module_deps(registry_path, name):
    reg = load(registry_path)
    for module in reg.get("modules", []):
        if module["name"] == name:
            for dep in module.get("deps", []):
                print(dep)
            return
    sys.exit(1)


def cmd_module_desc(registry_path, name):
    reg = load(registry_path)
    for module in reg.get("modules", []):
        if module["name"] == name:
            print(module.get("description", ""))
            return


def cmd_module_info(registry_path, name):
    reg = load(registry_path)
    for module in reg.get("modules", []):
        if module["name"] == name:
            print(f"=== love module: {module['name']} ===")
            print(f"File:          {module.get('file', '')}")
            print(f"Dependencies:  {', '.join(module.get('deps', [])) or '-'}")
            print(f"Description:   {module.get('description', '')}")
            print("")
            print(f"Tags:          {', '.join(module.get('tags', [])) or '-'}")
            print(f"Classes:       {', '.join(module.get('classes', [])) or '-'}")
            print(f"States:        {', '.join(module.get('states', [])) or '-'}")
            print(f"Pseudo:        {', '.join(module.get('pseudos', [])) or '-'}")
            print(f"Animations:    {', '.join(module.get('animations', [])) or '-'}")
            print(f"Presets:       {', '.join(module.get('presets', [])) or '-'}")
            return
    print(f"love: module '{name}' not found", file=sys.stderr)
    sys.exit(1)


def cmd_preset_modules(preset_path):
    data = load(preset_path)
    for module in data.get("modules", []):
        print(module)


def cmd_preset_meta(preset_path, field):
    data = load(preset_path)
    value = data.get(field, "")
    if isinstance(value, list):
        print(" ".join(value))
    else:
        print(value)


def cmd_preset_info(preset_path):
    data = load(preset_path)
    print(f"=== love preset: {data.get('name', '')} ===")
    print(f"Description:   {data.get('description', '')}")
    print(f"Modules:       {', '.join(data.get('modules', [])) or '-'}")
    print(f"Theme:         {data.get('theme', 'auto')}")
    print(f"Density:       {data.get('density', 'comfortable')}")
    print(f"RTL:           {data.get('rtl', False)}")
    print(f"HTMX:          {data.get('htmx', False)}")


def cmd_check_duplicate_tags(registry_path):
    reg = load(registry_path)
    seen = {}
    duplicates = []
    for module in reg.get("modules", []):
        for tag in module.get("tags", []):
            tag = tag.lower()
            if tag in seen:
                duplicates.append(f"  {tag}: {seen[tag]} and {module['name']}")
            else:
                seen[tag] = module["name"]
    for line in duplicates:
        print(line)
    if duplicates:
        sys.exit(1)


def cmd_write_love_json(path, preset, modules, registry_path):
    reg = load(registry_path)
    elements = set()
    animations = set()
    for module in reg.get("modules", []):
        if module["name"] in modules.split():
            for tag in module.get("tags", []):
                elements.add(tag)
            for anim in module.get("animations", []):
                animations.add(anim)
    data = {
        "preset-name": preset if preset else None,
        "info": "",
        "modules": sorted(set(modules.split())),
        "elements": sorted(elements),
        "animations": sorted(animations),
    }
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")


def cmd_love_json_field(path, field):
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    value = data.get(field, "")
    if isinstance(value, list):
        print(" ".join(str(v) for v in value))
    elif value is None:
        print("")
    else:
        print(value)


def main():
    if len(sys.argv) < 2:
        print("usage: registry_query.py <command> [args]", file=sys.stderr)
        sys.exit(1)

    command = sys.argv[1]
    args = sys.argv[2:]

    dispatch = {
        "modules": cmd_modules,
        "module-file": cmd_module_file,
        "module-deps": cmd_module_deps,
        "module-desc": cmd_module_desc,
        "module-info": cmd_module_info,
        "preset-modules": cmd_preset_modules,
        "preset-meta": cmd_preset_meta,
        "preset-info": cmd_preset_info,
        "check-duplicate-tags": cmd_check_duplicate_tags,
        "write-love-json": cmd_write_love_json,
        "love-json-field": cmd_love_json_field,
    }

    fn = dispatch.get(command)
    if fn is None:
        print(f"unknown command: {command}", file=sys.stderr)
        sys.exit(1)
    fn(*args)


if __name__ == "__main__":
    main()
