#!/usr/bin/env bats
# Tests for terminal.sh - Terminal utilities for window/tab manipulation

# Path to the script under test
SCRIPT="${BATS_TEST_DIRNAME}/../terminal.sh"

# Helper to capture output including escape sequences
# We use printf %q to make escape sequences visible for verification
escape_visible() {
    printf '%q' "$1"
}

#
# SYNTAX AND BASIC CHECKS
#

@test "script passes bash syntax check" {
    bash -n "$SCRIPT"
}

@test "script is executable" {
    [[ -x "$SCRIPT" ]]
}

#
# VERSION OUTPUT
#

@test "version flag shows version number" {
    run "$SCRIPT" --version
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ ^terminal\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "short version flag shows version number" {
    run "$SCRIPT" -v
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ ^terminal\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

#
# HELP OUTPUT
#

@test "help flag shows usage information" {
    run "$SCRIPT" --help
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal <command>" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "short help flag shows usage information" {
    run "$SCRIPT" -h
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal <command>" ]]
}

@test "no arguments shows usage" {
    run "$SCRIPT"
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal <command>" ]]
}

#
# INVALID COMMAND HANDLING
#

@test "unknown command shows error and usage" {
    run "$SCRIPT" invalid_command
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Unknown command: invalid_command" ]]
    [[ "$output" =~ "Usage:" ]]
}

#
# TITLE COMMAND
#

@test "title command without args shows usage error" {
    run "$SCRIPT" title
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal title" ]]
}

@test "title command outputs OSC 0 escape sequence" {
    run "$SCRIPT" title "Test Title"
    [[ "$status" -eq 0 ]]
    # Check for OSC 0 sequence: ESC ] 0 ; text BEL
    # printf %q produces: $'\033'\]0\;Test\ Title$'\a'
    visible=$(escape_visible "$output")
    [[ "$visible" =~ \]0 ]]
    [[ "$visible" =~ Test\ Title ]]
}

@test "title command handles multiple words" {
    run "$SCRIPT" title "Hello World Test"
    [[ "$status" -eq 0 ]]
    visible=$(escape_visible "$output")
    [[ "$visible" =~ Hello\ World\ Test ]]
}

#
# BADGE COMMAND
#

@test "badge command without args shows usage error" {
    run "$SCRIPT" badge
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal badge" ]]
}

@test "badge command outputs iTerm2 OSC 1337 sequence" {
    run "$SCRIPT" badge "test"
    # May show warning if not in iTerm2, but should still output sequence
    visible=$(escape_visible "$output")
    # Check for OSC 1337;SetBadgeFormat= sequence
    [[ "$visible" =~ 1337\;SetBadgeFormat= ]]
}

#
# RESET COMMAND
#

@test "reset command outputs terminal reset sequence" {
    run "$SCRIPT" reset
    [[ "$status" -eq 0 ]]
    # Check for ESC c (full reset)
    # Output is 2 bytes: ESC (0x1b) followed by 'c'
    [[ ${#output} -eq 2 ]]
    # Verify ends with 'c'
    [[ "$output" == *c ]]
}

#
# NOTIFY COMMAND
#

@test "notify command without args shows usage error" {
    run "$SCRIPT" notify
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal notify" ]]
}

#
# CWD COMMAND
#

@test "cwd command outputs OSC 7 sequence" {
    run "$SCRIPT" cwd /tmp
    [[ "$status" -eq 0 ]]
    # Check for OSC 7 sequence with file:// URL
    # printf %q produces: $'\033'\]7\;file://hostname/tmp$'\a'
    visible=$(escape_visible "$output")
    [[ "$visible" =~ \]7 ]]
    [[ "$visible" =~ file:// ]]
}

@test "cwd command includes directory path" {
    run "$SCRIPT" cwd /tmp
    [[ "$status" -eq 0 ]]
    visible=$(escape_visible "$output")
    [[ "$visible" =~ /tmp ]]
}

#
# PROFILE COMMAND
#

@test "profile command without args shows usage error" {
    run "$SCRIPT" profile
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal profile" ]]
}

@test "profile command outputs iTerm2 SetProfile sequence" {
    run "$SCRIPT" profile "Default"
    visible=$(escape_visible "$output")
    # Check for OSC 1337;SetProfile= sequence
    [[ "$visible" =~ 1337\;SetProfile=Default ]]
}

#
# MARK COMMAND
#

@test "mark command outputs iTerm2 SetMark sequence" {
    run "$SCRIPT" mark
    visible=$(escape_visible "$output")
    # Check for OSC 1337;SetMark sequence
    [[ "$visible" =~ 1337\;SetMark ]]
}

#
# ATTENTION COMMAND
#

@test "attention command outputs RequestAttention sequence" {
    run "$SCRIPT" attention
    visible=$(escape_visible "$output")
    # Check for OSC 1337;RequestAttention= sequence
    [[ "$visible" =~ 1337\;RequestAttention= ]]
}

@test "attention command accepts mode argument" {
    run "$SCRIPT" attention once
    visible=$(escape_visible "$output")
    [[ "$visible" =~ RequestAttention=once ]]
}

#
# PROGRESS COMMAND
#

@test "progress command without args shows usage error" {
    run "$SCRIPT" progress
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal progress" ]]
}

@test "progress command outputs OSC 9 sequence with value" {
    run "$SCRIPT" progress 50
    visible=$(escape_visible "$output")
    # Check for Progress=50 in output
    [[ "$visible" =~ Progress=50 ]]
}

@test "progress done clears indicator" {
    run "$SCRIPT" progress done
    visible=$(escape_visible "$output")
    # Check for RemoveBadge sequence
    [[ "$visible" =~ RemoveBadge ]]
}

#
# INFO COMMAND
#

@test "info command shows terminal information header" {
    run "$SCRIPT" info
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Terminal Information:" ]]
}

@test "info command shows TERM variable" {
    run "$SCRIPT" info
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "TERM:" ]]
}

@test "info command shows TERM_PROGRAM variable" {
    run "$SCRIPT" info
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "TERM_PROGRAM:" ]]
}

@test "info command shows detected capabilities section" {
    run "$SCRIPT" info
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Detected capabilities:" ]]
}

#
# COLORS COMMAND
#

@test "colors command shows standard colors header" {
    run "$SCRIPT" colors
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Standard colors" ]]
}

@test "colors command shows bright colors header" {
    run "$SCRIPT" colors
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Bright colors" ]]
}

@test "colors command shows 216 colors header" {
    run "$SCRIPT" colors
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "216 colors" ]]
}

@test "colors command shows grayscale header" {
    run "$SCRIPT" colors
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Grayscale" ]]
}

@test "colors command outputs escape sequences" {
    run "$SCRIPT" colors
    [[ "$status" -eq 0 ]]
    visible=$(escape_visible "$output")
    # Check for color escape sequence pattern (ESC[48;5;Nm)
    [[ "$visible" =~ 48\;5\; ]]
}

#
# CURSOR COMMAND
#

@test "cursor command without args shows usage error" {
    run "$SCRIPT" cursor
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal cursor" ]]
    [[ "$output" =~ "block" ]]
    [[ "$output" =~ "underline" ]]
    [[ "$output" =~ "bar" ]]
}

@test "cursor block outputs DECSCUSR sequence" {
    run "$SCRIPT" cursor block
    [[ "$status" -eq 0 ]]
    # DECSCUSR for block (non-blinking) is code 2: ESC [ 2 SP q
    # printf %q produces: $'\033'\[2\ q
    visible=$(escape_visible "$output")
    [[ "$visible" =~ \[2\  ]]
    [[ "$visible" =~ q ]]
}

@test "cursor underline outputs DECSCUSR sequence" {
    run "$SCRIPT" cursor underline
    [[ "$status" -eq 0 ]]
    # DECSCUSR for underline (non-blinking) is code 4
    visible=$(escape_visible "$output")
    [[ "$visible" =~ \[4\  ]]
    [[ "$visible" =~ q ]]
}

@test "cursor bar outputs DECSCUSR sequence" {
    run "$SCRIPT" cursor bar
    [[ "$status" -eq 0 ]]
    # DECSCUSR for bar (non-blinking) is code 6
    visible=$(escape_visible "$output")
    [[ "$visible" =~ \[6\  ]]
    [[ "$visible" =~ q ]]
}

@test "cursor block-blink outputs blinking cursor sequence" {
    run "$SCRIPT" cursor block-blink
    [[ "$status" -eq 0 ]]
    # DECSCUSR for blinking block is code 1
    visible=$(escape_visible "$output")
    [[ "$visible" =~ \[1\  ]]
    [[ "$visible" =~ q ]]
}

@test "cursor invalid style shows error" {
    run "$SCRIPT" cursor invalid
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Unknown cursor style: invalid" ]]
}

#
# CLIPBOARD COMMAND
#

@test "clipboard command without args shows usage error" {
    run "$SCRIPT" clipboard
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal clipboard" ]]
}

@test "clipboard get outputs OSC 52 query sequence" {
    run "$SCRIPT" clipboard get
    [[ "$status" -eq 0 ]]
    visible=$(escape_visible "$output")
    # OSC 52 query: ESC ] 52 ; c ; ? BEL
    [[ "$visible" =~ 52\;c\;\? ]]
}

@test "clipboard set outputs OSC 52 with base64 content" {
    run "$SCRIPT" clipboard set "hello"
    [[ "$status" -eq 0 ]]
    visible=$(escape_visible "$output")
    # OSC 52 set: ESC ] 52 ; c ; base64 BEL
    [[ "$visible" =~ 52\;c\; ]]
    # "hello" in base64 is "aGVsbG8="
    [[ "$visible" =~ aGVsbG8= ]]
}

@test "clipboard invalid action shows error" {
    run "$SCRIPT" clipboard invalid
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Unknown clipboard action: invalid" ]]
}

#
# IMAGE COMMAND
#

@test "image command without args shows usage error" {
    run "$SCRIPT" image
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal image" ]]
}

@test "image command with nonexistent file shows error" {
    run "$SCRIPT" image /nonexistent/file.png
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "File not found" ]]
}

#
# LINK COMMAND
#

@test "link command without args shows usage error" {
    run "$SCRIPT" link
    [[ "$status" -eq 1 ]]
    [[ "$output" =~ "Usage: terminal link" ]]
}

@test "link command outputs OSC 8 hyperlink sequence" {
    run "$SCRIPT" link "https://example.com"
    [[ "$status" -eq 0 ]]
    visible=$(escape_visible "$output")
    # OSC 8 hyperlink: ESC ] 8 ; ; url ST text ESC ] 8 ; ; ST
    [[ "$visible" =~ 8\;\;https://example.com ]]
}

@test "link command with custom text includes text" {
    run "$SCRIPT" link "https://example.com" "Click here"
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "Click here" ]]
}

@test "link command without text uses URL as text" {
    run "$SCRIPT" link "https://example.com"
    [[ "$status" -eq 0 ]]
    [[ "$output" =~ "https://example.com" ]]
}
