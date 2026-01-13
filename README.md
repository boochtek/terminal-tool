# terminal-tool

Terminal utilities for window/tab manipulation, badges, notifications, and more.

## Installation

### Homebrew (recommended)

```bash
brew install boochtek/tap/terminal-tool
```

### Manual

```bash
git clone https://github.com/boochtek/terminal-tool.git
cd terminal-tool
make install
```

## Usage

```bash
terminal <command> [args]
```

## Commands

### Basic Commands

| Command | Description |
|---------|-------------|
| `terminal title <text>` | Set window/tab title |
| `terminal reset` | Reset terminal state (colors, cursor, etc.) |
| `terminal info` | Show terminal information |
| `terminal colors` | Display color palette |

### iTerm2-Specific Commands

These commands work best in iTerm2 but will show a warning in other terminals:

| Command | Description |
|---------|-------------|
| `terminal badge <text>` | Set corner watermark (badge) |
| `terminal profile <name>` | Switch to named profile |
| `terminal mark` | Set navigation mark at cursor |
| `terminal attention` | Request attention (bounce dock icon) |
| `terminal progress <0-100\|done>` | Show progress in tab bar |

### Advanced Commands

| Command | Description |
|---------|-------------|
| `terminal notify <message>` | Send notification |
| `terminal cwd [directory]` | Set working directory for new tabs |
| `terminal cursor <style>` | Change cursor style |
| `terminal clipboard get\|set` | Access system clipboard (works over SSH!) |
| `terminal image <file>` | Display inline image |
| `terminal link <url> [text]` | Create clickable hyperlink |

## Examples

```bash
# Set window title
terminal title "My Project"

# Show iTerm2 badge
terminal badge "PROD"

# Reset terminal after a program misbehaves
terminal reset

# Notify when a long command completes
make build && terminal notify "Build complete!"

# Create a clickable link
terminal link "https://github.com" "GitHub"

# Display an image inline
terminal image screenshot.png

# Copy text to clipboard (works over SSH!)
echo "copied text" | terminal clipboard set

# Change cursor to a bar
terminal cursor bar

# Show terminal capabilities
terminal info

# Display color palette
terminal colors
```

## Cursor Styles

The `cursor` command accepts these styles:

- `block` - Solid block cursor
- `underline` - Underline cursor
- `bar` - Vertical bar cursor

Append `-blink` for blinking variants (e.g., `block-blink`).

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

For those interested in the underlying escape sequences:

| Command | Escape Sequence |
|---------|-----------------|
| title | OSC 0 (Set window/icon title) |
| badge | OSC 1337;SetBadgeFormat |
| reset | RIS (Reset to Initial State) |
| notify | OSC 9 / terminal-notifier |
| cwd | OSC 7 (Set working directory) |
| profile | OSC 1337;SetProfile |
| mark | OSC 1337;SetMark |
| attention | OSC 1337;RequestAttention |
| progress | OSC 9 |
| cursor | DECSCUSR (Set Cursor Style) |
| clipboard | OSC 52 |
| image | OSC 1337;File |
| link | OSC 8 (Hyperlink) |

## Dependencies

- **Required**: Bash 3.2+
- **Recommended**: `terminal-notifier` (for `notify` command outside iTerm2)

Install terminal-notifier with:
```bash
brew install terminal-notifier
```

## Development

Run tests:
```bash
make test
# or
bats test/
```

## License

MIT
