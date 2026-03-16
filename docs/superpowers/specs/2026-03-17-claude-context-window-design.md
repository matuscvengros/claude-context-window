# claude-context-window Design Spec

## Problem

Claude Code users have no real-time visibility into how much of their context window has been consumed during a session. This makes it hard to know when to checkpoint, clear, or wrap up before hitting compaction. Users need a simple, always-visible indicator in the TUI status bar.

## Solution

An npm package (`claude-context-window`) that provides:
1. A **statusline script** that displays context usage as a colored progress bar in Claude Code's TUI footer
2. An **npx installer/uninstaller** that configures everything automatically

## Display Format

```
Opus 4.6 │ 100K/1M tokens │ █░░░░░░░░░ 10%     ← green
Opus 4.6 │ 500K/1M tokens │ █████░░░░░ 50%     ← yellow
Opus 4.6 │ 780K/1M tokens │ ████████░░ 78%     ← orange
Opus 4.6 │ 900K/1M tokens │ █████████░ 90%     ← red
```

Layout: **Model | Tokens | Bar**

The bar represents context **used** (fills up over time):
- **Green** (`\x1b[32m`): 0–50% used — plenty of room
- **Yellow** (`\x1b[33m`): 50–75% used — getting there
- **Orange** (`\x1b[38;5;208m`): 75–90% used — caution
- **Red** (`\x1b[31m`): 90–100% used — nearly full

Bar: 10 segments using `█` (filled) and `░` (empty). Token counts formatted human-readable (100K, 1M).

**Note:** The bar shows raw `used_percentage` as reported by Claude Code — no normalization for auto-compaction buffer. This matches what users see from `/context` and avoids reliance on internal thresholds that may change.

**Early session:** Before the first API call, `used_percentage` and `current_usage` may be null. The bar shows a zeroed state: `Model │ waiting... │ ░░░░░░░░░░ 0%`

**Post-compaction:** When auto-compaction triggers, `used_percentage` drops sharply and the bar resets accordingly. This is correct behavior.

## Architecture

### Runtime: StatusLine Script

A self-contained Node.js script (`statusline.js`) with zero dependencies. Target execution time: sub-100ms.

1. Reads JSON from stdin (Claude Code invokes this periodically; if a new update triggers while still running, the in-flight execution is cancelled)
2. Parses fields from `context_window`, `model`, etc.
3. Handles null/missing values gracefully (early session state)
4. Calculates bar segments and color from `used_percentage`
5. Derives token counts: `usedTokens = context_window_size * used_percentage / 100`
6. Outputs formatted ANSI string to stdout

**Input JSON schema** (from Claude Code — relevant fields):
```json
{
  "context_window": {
    "remaining_percentage": 78.5,
    "used_percentage": 21.5,
    "context_window_size": 1000000,
    "current_usage": {
      "input_tokens": 8500,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 2000
    }
  },
  "model": {
    "display_name": "Opus 4.6"
  },
  "session_id": "abc123",
  "workspace": {
    "current_dir": "/path/to/project"
  }
}
```

**Key:** `current_usage` is an object (not a scalar) nested inside `context_window`, and is null before the first API call. Token display is derived from `context_window_size * used_percentage / 100` for reliability.

### Installer: CLI (`bin/cli.js`)

**`npx claude-context-window@latest install`**:
1. Resolve `~/.claude/` directory, create if absent
2. Copy `statusline.js` to `~/.claude/claude-context-window.js`
3. Read `~/.claude/settings.json` (create with `{}` if absent)
4. If `statusLine` already exists and command does NOT contain `claude-context-window`, warn and prompt to overwrite
5. Set `statusLine: { type: "command", command: "node <path>/claude-context-window.js" }`
   - On Windows: use forward slashes in the command string (Git Bash compatibility)
6. Write settings back (preserve existing settings, only touch `statusLine`)
7. Print success: "claude-context-window installed. Restart Claude Code to activate."

**`npx claude-context-window@latest uninstall`**:
1. Remove `~/.claude/claude-context-window.js` if it exists
2. If `~/.claude/settings.json` does not exist, print "nothing to uninstall" and exit cleanly
3. Read `~/.claude/settings.json`
4. Remove `statusLine` entry only if command contains `claude-context-window`
5. Write settings back
6. Print success message

**Detection logic:** A statusLine entry is "ours" if `statusLine.command` contains the string `claude-context-window`.

## Package Structure

```
claude-context-window/
├── bin/
│   └── cli.js                    # npx entry point
├── src/
│   └── statusline.js             # StatusLine script (copied at install)
├── test/
│   ├── statusline.test.js        # Unit tests for bar logic
│   └── cli.test.js               # Unit tests for install/uninstall
├── package.json
├── README.md
├── LICENSE                       # MIT
└── .github/
    └── workflows/
        ├── ci.yml                # Test on push/PR
        └── publish.yml           # Publish to npm on tag
```

## Cross-Platform Support

- **Node.js only** — zero native dependencies. Claude Code already requires Node.js.
- All file paths use `os.homedir()` + `path.join()` for filesystem operations.
- **Windows:** Claude Code runs statusLine commands through Git Bash. The command string written to settings.json must use forward slashes (use `path.posix.join()` or manual slash replacement for the command path).
- ANSI colors supported on: macOS Terminal, iTerm, Linux terminals, Windows Terminal, modern PowerShell, Git Bash.

## CI/CD

### `.github/workflows/ci.yml` — Test (runs on push & PR)
- Matrix: Node 18, 20, 22 on ubuntu-latest, macos-latest, windows-latest
- Steps: install deps, run unit tests
- Tests cover: color threshold logic, bar rendering, token formatting, JSON parsing, null/missing field handling, install/uninstall CLI logic (mocked filesystem)

### `.github/workflows/publish.yml` — Publish (runs on `v*` tags)
- Runs full CI test suite first
- Publishes to npm registry

## README Badges

In order:
1. **Build** — GitHub Actions CI status badge
2. **npm version** — current published version
3. **Downloads** — monthly npm downloads
4. **License** — MIT

## npm Package Config

```json
{
  "name": "claude-context-window",
  "version": "0.1.0",
  "description": "Real-time context window usage bar for Claude Code",
  "bin": {
    "claude-context-window": "./bin/cli.js"
  },
  "scripts": {
    "test": "node --test test/*.test.js"
  },
  "license": "MIT",
  "engines": {
    "node": ">=18"
  },
  "keywords": ["claude", "claude-code", "context-window", "statusline", "cli"]
}
```

Zero runtime dependencies. Uses Node.js built-in test runner.
