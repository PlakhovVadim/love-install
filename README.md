# love-install

The installer and command-line interface for Love.css.

This repository contains the love command, the module registry, the presets, and the project templates. It does not contain the CSS itself — that lives in the love-css repository, which is downloaded on demand or cloned locally.

## What this repository contains

- bin/ — the love command for Unix (POSIX sh), Windows CMD, and Windows PowerShell.
- lib/ — the shell modules that implement each command.
- cli/ — Python helpers for JSON queries and HTML scanning.
- registry/ — the module registry and preset definitions.
- templates/ — starter HTML pages for each preset.
- install.sh and install.ps1 — the installers for Unix and Windows.

## Installation

Unix, macOS, Git Bash on Windows:

    git clone https://github.com/PlakhovVadim/love-install.git
    cd love-install
    ./install.sh

Windows PowerShell:

    git clone https://github.com/PlakhovVadim/love-install.git
    cd love-install
    .\install.ps1

The installer puts the love command in your PATH and, optionally, clones love-css into the current directory. After it finishes, restart your terminal.

To verify:

    love version

To remove the command later:

    ./uninstall.sh

## How the two repositories work together

love-install knows how to use love-css but does not store it. When you run love install or love add, the CLI looks for love-css in three places, in this order:

1. The LOVE_CSS_HOME environment variable, if set.
2. A sibling directory named love-css next to love-install.
3. The user cache at ~/.cache/love-css/.

If none of these exist, the CLI tells you how to provide love-css and exits.

## Commands

### Installing modules and presets

| Command | Description |
|---|---|
| love install preset | Install a preset. Copies its modules into your css directory. |
| love install custom | Create an empty recipe for manual assembly. |
| love install love-css | Clone the full love-css repository into the current directory. |
| love add module | Add a single module and its dependencies. |
| love remove module | Remove a module. Checks dependencies first. |

### Inspecting

| Command | Description |
|---|---|
| love list | List all available modules and presets. |
| love module list | List modules with plus or minus markers for the current project. |
| love info -m module | Show details about one module. |
| love info -p preset | Show details about one preset. |
| love status | Show installed modules, active preset, and version. |
| love check | Scan HTML files in the current directory and report required modules. |
| love doctor | Validate the registry. |

### Projects

| Command | Description |
|---|---|
| love new preset dir | Create a new project from a template. |
| love update | Update installed modules from love-css. |
| love help | Show help. |
| love version | Show CLI version. |

## A typical first session

Step one. Create a project directory.

    mkdir my-project
    cd my-project

Step two. Install a preset. This copies the necessary CSS files into css/ and creates a small recipe file at the project root.

    love install admin

Step three. Check what was installed.

    love status
    love module list

Step four. Add any extra modules you need.

    love add tooltip
    love add toast

Step five. Link the CSS in your HTML, then start writing markup.

    <link rel="stylesheet" href="css/love.reset.css">
    <link rel="stylesheet" href="css/love.tokens.css">
    <link rel="stylesheet" href="css/love.base.css">
    <link rel="stylesheet" href="css/love.button.css">

If you are not sure which modules you need, run:

    love check

It scans every HTML file in the current directory, finds the elements and classes that Love.css knows about, and tells you which modules are missing.

## The custom preset

If you do not want to commit to a preset, start with the empty one.

    love install custom

This creates a love.json recipe with no modules. Add them one by one:

    love add reset
    love add tokens
    love add base
    love add button
    love add card

After each command, love.json is updated. The file is a plain recipe — you can commit it, share it, or delete it. Deleting it does not break anything; the modules are already on disk.

## Where love-css is downloaded from

The default URL is:

    https://github.com/PlakhovVadim/love-css.git

To use a fork or a local copy, set the environment variable before running love:

    export LOVE_CSS_HOME=/path/to/your/love-css

On Windows PowerShell:

    $env:LOVE_CSS_HOME = "C:\path\to\your\love-css"

## Platform notes

Unix and macOS: the installer creates a symlink at ~/.local/bin/love. Make sure ~/.local/bin is in your PATH. The installer prints the line to add if it is not.

Windows: the installer adds the bin directory to your user PATH and creates a shim in %LOCALAPPDATA%\Microsoft\WindowsApps. Git for Windows must be installed, because the CLI runs in Git Bash under the hood.

## Requirements

- Unix shell (POSIX sh or bash) on Linux, macOS, or Git Bash for Windows.
- Python 3 for the JSON query helper and the HTML scanner. It is used by love list, love status, love check, love info, love doctor.
- Git for cloning love-css on demand.

The installer checks for these and tells you if anything is missing.

## Uninstalling

Unix:

    ./uninstall.sh

Windows: remove the bin directory from your PATH manually, then delete the shim at %LOCALAPPDATA%\Microsoft\WindowsApps\love.cmd.

## License

MIT. See LICENSE for details.

## Contributing

Issues and pull requests are welcome. The registry and the shell modules are the two main extension points. For larger changes, please open an issue first.
