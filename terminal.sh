#!/bin/bash
# terminal - Terminal utilities for window/tab manipulation
# https://github.com/boochtek/terminal-tool

set -euo pipefail

VERSION="0.9.0"

# Detect terminal type
is_iterm2() {
    [[ "${TERM_PROGRAM:-}" == "iTerm.app" ]]
}

is_apple_terminal() {
    [[ "${TERM_PROGRAM:-}" == "Apple_Terminal" ]]
}

# Main usage
usage() {
    cat >&2 <<EOF
Usage: terminal <command> [args]

Terminal utilities for window/tab manipulation.

Commands:
  title <text>           Set window/tab title
  badge <text>           Set iTerm2 badge (corner watermark)
  reset                  Reset terminal state (colors, cursor, etc.)
  notify <message>       Send notification when command completes
  cwd [directory]        Set working directory for new tabs
  profile <name>         Switch iTerm2 profile
  mark                   Set navigation mark at current position
  attention              Request attention (bounce dock icon)
  progress <0-100|done>  Show progress indicator in tab bar
  info                   Show terminal information
  colors                 Display color palette
  cursor <style>         Change cursor style (block|underline|bar)
  clipboard get|set      Access system clipboard (works over SSH)
  image <file>           Display inline image (iTerm2/kitty)
  link <url> [text]      Create clickable hyperlink

Options:
  --help                 Show this help message
  --version              Show version number

EOF
    exit 1
}

# OSC (Operating System Command) helper
# Usage: osc <code> <args>
osc() {
    local code="$1"
    shift
    printf '\033]%s\007' "${code};$*"
}

# iTerm2-specific OSC 1337
iterm2_osc() {
    printf '\033]1337;%s\007' "$*"
}

#
# COMMAND IMPLEMENTATIONS
#

cmd_title() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: terminal title <title>" >&2
        exit 1
    fi
    # OSC 0 sets both window and icon title
    # Works with xterm, iTerm2, Terminal.app, and most modern terminals
    osc 0 "$*"
}

cmd_badge() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: terminal badge <text>" >&2
        echo "Sets iTerm2 badge (corner watermark). Use '' to clear." >&2
        exit 1
    fi
    if ! is_iterm2; then
        echo "Warning: badge only works in iTerm2" >&2
    fi
    # Badge format is base64 encoded
    local encoded
    encoded=$(printf '%s' "$*" | base64)
    iterm2_osc "SetBadgeFormat=${encoded}"
}

cmd_reset() {
    # Reset various terminal states
    # \033c       - Full reset (RIS - Reset to Initial State)
    # \033[0m     - Reset text attributes
    # \033[?25h   - Show cursor
    # \033[?7h    - Enable line wrapping
    printf '\033c'
}

cmd_notify() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: terminal notify <message>" >&2
        exit 1
    fi
    local message="$*"

    if is_iterm2; then
        # iTerm2 OSC 9 notification
        osc 9 "$message"
    elif command -v terminal-notifier &>/dev/null; then
        # Fallback to terminal-notifier
        terminal-notifier -message "$message" -title "Terminal"
    else
        echo "Error: notify requires iTerm2 or terminal-notifier" >&2
        echo "Install with: brew install terminal-notifier" >&2
        exit 1
    fi
}

cmd_cwd() {
    local dir="${1:-$PWD}"
    # Expand to absolute path
    dir=$(cd "$dir" && pwd)
    # OSC 7 sets the working directory (used by Terminal.app for new tabs)
    # Format: file://hostname/path
    local hostname
    hostname=$(hostname)
    printf '\033]7;file://%s%s\007' "$hostname" "$dir"
}

cmd_profile() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: terminal profile <name>" >&2
        echo "Switches to the named iTerm2 profile." >&2
        exit 1
    fi
    if ! is_iterm2; then
        echo "Warning: profile only works in iTerm2" >&2
    fi
    iterm2_osc "SetProfile=$1"
}

cmd_mark() {
    if ! is_iterm2; then
        echo "Warning: mark only works in iTerm2" >&2
    fi
    # Set a mark at the current cursor position for navigation
    iterm2_osc "SetMark"
}

cmd_attention() {
    if ! is_iterm2; then
        echo "Warning: attention only works in iTerm2" >&2
    fi
    # Request attention - bounces dock icon if window not focused
    # yes=start, no=stop, once=bounce once, fireworks=special effect
    local mode="${1:-yes}"
    iterm2_osc "RequestAttention=${mode}"
}

cmd_progress() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: terminal progress <0-100|done>" >&2
        echo "Shows progress indicator in iTerm2 tab bar." >&2
        exit 1
    fi
    if ! is_iterm2; then
        echo "Warning: progress only works in iTerm2" >&2
    fi
    local value="$1"
    if [[ "$value" == "done" ]]; then
        # Clear progress indicator
        osc 9 "RemoveBadge"
        iterm2_osc "RemoveBadge"
    else
        # Set progress (0-100)
        # Note: iTerm2 shows this in the tab title area
        osc 9 "Progress=${value}"
    fi
}

cmd_info() {
    echo "Terminal Information:"
    echo "  TERM:         ${TERM:-unset}"
    echo "  TERM_PROGRAM: ${TERM_PROGRAM:-unset}"
    echo "  COLORTERM:    ${COLORTERM:-unset}"
    echo "  ITERM_SESSION_ID: ${ITERM_SESSION_ID:-unset}"

    # Terminal size
    if command -v tput &>/dev/null; then
        echo "  Columns:      $(tput cols)"
        echo "  Lines:        $(tput lines)"
        echo "  Colors:       $(tput colors)"
    fi

    # Detect capabilities
    echo ""
    echo "Detected capabilities:"
    if is_iterm2; then
        echo "  iTerm2:       yes (full feature support)"
    elif is_apple_terminal; then
        echo "  Terminal.app: yes (basic features)"
    else
        echo "  Generic:      assuming xterm-compatible"
    fi

    # Check for 256 color support
    if [[ "${TERM:-}" == *"256color"* ]] || [[ "${COLORTERM:-}" == "truecolor" ]]; then
        echo "  256 colors:   yes"
    fi

    # Check for truecolor support
    if [[ "${COLORTERM:-}" == "truecolor" ]] || [[ "${COLORTERM:-}" == "24bit" ]]; then
        echo "  True color:   yes"
    fi
}

cmd_colors() {
    echo "Standard colors (0-7):"
    for i in {0..7}; do
        printf '\033[48;5;%dm  %3d  \033[0m' "$i" "$i"
    done
    echo ""

    echo "Bright colors (8-15):"
    for i in {8..15}; do
        printf '\033[48;5;%dm  %3d  \033[0m' "$i" "$i"
    done
    echo ""

    echo ""
    echo "216 colors (16-231):"
    for i in {16..231}; do
        printf '\033[48;5;%dm%4d\033[0m' "$i" "$i"
        if (( (i - 15) % 36 == 0 )); then
            echo ""
        fi
    done

    echo ""
    echo "Grayscale (232-255):"
    for i in {232..255}; do
        printf '\033[48;5;%dm %3d \033[0m' "$i" "$i"
    done
    echo ""

    # True color test if supported
    if [[ "${COLORTERM:-}" == "truecolor" ]] || [[ "${COLORTERM:-}" == "24bit" ]]; then
        echo ""
        echo "True color gradient:"
        for i in {0..76}; do
            local r=$((255 - i * 255 / 76))
            local g=$((i * 510 / 76))
            local b=$((i * 255 / 76))
            (( g > 255 )) && g=$((510 - g))
            printf '\033[48;2;%d;%d;%dm \033[0m' "$r" "$g" "$b"
        done
        echo ""
    fi
}

cmd_cursor() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: terminal cursor <style>" >&2
        echo "Styles: block, underline, bar" >&2
        echo "Append '-blink' for blinking (e.g., block-blink)" >&2
        exit 1
    fi
    local style="$1"
    local code
    case "$style" in
        block)          code=2 ;;
        block-blink)    code=1 ;;
        underline)      code=4 ;;
        underline-blink) code=3 ;;
        bar)            code=6 ;;
        bar-blink)      code=5 ;;
        *)
            echo "Unknown cursor style: $style" >&2
            echo "Valid styles: block, underline, bar (append -blink for blinking)" >&2
            exit 1
            ;;
    esac
    # DECSCUSR - Set Cursor Style
    printf '\033[%d q' "$code"
}

cmd_clipboard() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: terminal clipboard get|set [text]" >&2
        echo "Access system clipboard via OSC 52 (works over SSH)." >&2
        exit 1
    fi
    local action="$1"
    shift
    case "$action" in
        get)
            # Request clipboard contents - terminal should respond with OSC 52
            # Note: Not all terminals support this, and response handling is complex
            printf '\033]52;c;?\007'
            echo "(Note: clipboard response is sent to terminal input)" >&2
            ;;
        set)
            if [[ $# -eq 0 ]]; then
                # Read from stdin
                local content
                content=$(cat)
            else
                local content="$*"
            fi
            local encoded
            encoded=$(printf '%s' "$content" | base64 | tr -d '\n')
            printf '\033]52;c;%s\007' "$encoded"
            ;;
        *)
            echo "Unknown clipboard action: $action" >&2
            echo "Use 'get' or 'set'" >&2
            exit 1
            ;;
    esac
}

cmd_image() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: terminal image <file>" >&2
        echo "Displays an inline image (iTerm2/kitty)." >&2
        exit 1
    fi
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        exit 1
    fi

    if is_iterm2; then
        # iTerm2 inline image protocol
        local filename
        filename=$(basename "$file")
        local encoded
        encoded=$(base64 < "$file")
        printf '\033]1337;File=name=%s;inline=1:%s\007' \
            "$(printf '%s' "$filename" | base64)" \
            "$encoded"
    else
        # Try kitty protocol as fallback
        # Note: This is a simplified implementation
        echo "Warning: Full image support requires iTerm2" >&2
        echo "File: $file" >&2
    fi
}

cmd_link() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: terminal link <url> [text]" >&2
        echo "Creates a clickable hyperlink using OSC 8." >&2
        exit 1
    fi
    local url="$1"
    local text="${2:-$url}"
    # OSC 8 hyperlink format
    printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$url" "$text"
    echo ""  # Newline after link
}

#
# MAIN
#

if [[ $# -eq 0 ]]; then
    usage
fi

case "$1" in
    --help|-h)
        usage
        ;;
    --version|-v)
        echo "terminal $VERSION"
        exit 0
        ;;
esac

command="$1"
shift

case "$command" in
    title)      cmd_title "$@" ;;
    badge)      cmd_badge "$@" ;;
    reset)      cmd_reset "$@" ;;
    notify)     cmd_notify "$@" ;;
    cwd)        cmd_cwd "$@" ;;
    profile)    cmd_profile "$@" ;;
    mark)       cmd_mark "$@" ;;
    attention)  cmd_attention "$@" ;;
    progress)   cmd_progress "$@" ;;
    info)       cmd_info "$@" ;;
    colors)     cmd_colors "$@" ;;
    cursor)     cmd_cursor "$@" ;;
    clipboard)  cmd_clipboard "$@" ;;
    image)      cmd_image "$@" ;;
    link)       cmd_link "$@" ;;
    *)
        echo "Unknown command: $command" >&2
        usage
        ;;
esac
