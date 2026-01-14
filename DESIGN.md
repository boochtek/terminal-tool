# Design Document: terminal-tool

This document describes the design and implementation of the `terminal` command-line tool.

## Overview

A bash utility providing terminal manipulation through standard escape sequences (primarily OSC codes). Works best with iTerm2 but degrades gracefully on other terminals.

## Commands

| Command | Description | Escape Sequence |
|---------|-------------|-----------------|
| `title <text>` | Set window/tab title | OSC 0 |
| `badge <text>` | Set iTerm2 badge | OSC 1337;SetBadgeFormat |
| `reset` | Reset terminal state | RIS (Reset to Initial State) |
| `notify <message>` | Send notification | OSC 9 (iTerm2) + terminal-notifier fallback |
| `cwd [dir]` | Set CWD for new tabs | OSC 7 |
| `profile <name>` | Switch iTerm2 profile | OSC 1337;SetProfile |
| `mark` | Set navigation mark | OSC 1337;SetMark |
| `attention` | Request attention (bounce dock) | OSC 1337;RequestAttention |
| `progress <0-100\|done>` | Show progress in tab | OSC 9 |
| `info` | Show terminal info | Query $TERM, $TERM_PROGRAM, tput |
| `colors` | Display color palette | ANSI color codes |
| `cursor <style>` | Change cursor style | DECSCUSR |
| `clipboard get\|set` | Access clipboard | OSC 52 |
| `image <file>` | Display inline image | OSC 1337;File (iTerm2) |
| `link <url> [text]` | Create clickable hyperlink | OSC 8 |

## Repository Structure

```
terminal-tool/
├── terminal.sh         # Main bash script (installed as 'terminal')
├── README.md           # User documentation
├── DESIGN.md           # This file
├── LICENSE             # MIT
├── Makefile            # Install target
└── test/
    └── terminal.bats   # BATS test suite
```

## Key Design Decisions

1. **Single file script**: Keep everything in one `terminal.sh` bash script for simplicity
2. **Graceful degradation**: Commands show warnings but work where supported
3. **Recommended dependency**: `terminal-notifier` (Homebrew package) as fallback for `notify` outside iTerm2
4. **Exit codes**: `--help` exits 0 (success), errors exit 1
5. **Output routing**: Help goes to stdout, errors to stderr
6. **BATS tests**: Comprehensive test suite verifying escape sequence output

## Terminal Compatibility

| Feature | iTerm2 | Terminal.app | xterm | kitty |
|---------|--------|--------------|-------|-------|
| title | ✓ | ✓ | ✓ | ✓ |
| reset | ✓ | ✓ | ✓ | ✓ |
| info | ✓ | ✓ | ✓ | ✓ |
| colors | ✓ | ✓ | ✓ | ✓ |
| cursor | ✓ | ✓ | ✓ | ✓ |
| cwd | ✓ | ✓ | ✓ | ✓ |
| link | ✓ | ✓ | ✓ | ✓ |
| clipboard | ✓ | partial | ✓ | ✓ |
| badge | ✓ | - | - | - |
| profile | ✓ | - | - | - |
| mark | ✓ | - | - | - |
| attention | ✓ | - | - | - |
| progress | ✓ | - | - | - |
| notify | ✓ | via terminal-notifier | - | - |
| image | ✓ | - | - | partial |

## Escape Sequence Reference

- **OSC (Operating System Command)**: `\033]<code>;<args>\007`
- **CSI (Control Sequence Introducer)**: `\033[<params><cmd>`
- **DECSCUSR**: `\033[<n> q` where n=1-6 sets cursor style

### Cursor Style Codes (DECSCUSR)
- 1 = blinking block
- 2 = steady block
- 3 = blinking underline
- 4 = steady underline
- 5 = blinking bar
- 6 = steady bar

## Development

```bash
# Run tests
make test
# or
bats test/

# Install locally
make install PREFIX=~/.local

# Uninstall
make uninstall PREFIX=~/.local
```

## Homebrew Installation

```bash
brew install boochtek/tap/terminal-tool
```

The Homebrew formula:
- Downloads from GitHub release tarball
- Installs `terminal.sh` as `terminal`
- Recommends `terminal-notifier` for notify fallback
- Uses `bats-core` for test dependencies
