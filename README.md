# Claude Code: Context Window

[![CI](https://github.com/matuscvengros/claude-context-window/actions/workflows/ci.yml/badge.svg)](https://github.com/matuscvengros/claude-context-window/actions/workflows/ci.yml)
[![npm version](https://img.shields.io/npm/v/claude-context-window)](https://www.npmjs.com/package/claude-context-window)
[![Downloads](https://img.shields.io/npm/dm/claude-context-window)](https://www.npmjs.com/package/claude-context-window)
[![License](https://img.shields.io/npm/l/claude-context-window)](https://github.com/matuscvengros/claude-context-window/blob/main/LICENSE)

Real-time context window usage bar for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Shows a two-line status bar in Claude Code with project info on the first line and a color-coded context window progress bar on the second.

```
[user] [project]:[owner@repo-name]/[main] [+3 ~2]
[Opus 4.6] [100K/1M] █░░░░░░░░░ [10%]     ← green
```

The first line shows the OS username, project directory, a clickable link to the git repo as `owner@repo` (Cmd/Ctrl+click), branch name, and staged/modified file counts. The second line shows the model (with effort level if available), token usage, and a color-coded progress bar.

## Installation

```sh
npx claude-context-window@latest install
```

Copies the script to `~/.claude/statusline.js` and configures `~/.claude/settings.json`. Restart Claude Code to activate.

To remove:

```sh
npx claude-context-window@latest uninstall
```

## How it works

Claude Code's [status line](https://code.claude.com/docs/en/statusline) is a customizable bar at the bottom of the terminal. It runs a shell command after each assistant message, piping JSON session data to stdin. The command's stdout becomes the status bar content.

This tool provides that command: a Node.js script that reads the JSON and outputs two lines — project/git info and a color-coded context window progress bar.

**Colors indicate context usage:**

| Color  | Usage   | Meaning       |
|--------|---------|---------------|
| Green  | 0–50%   | Plenty of room |
| Yellow | 50–75%  | Getting there |
| Orange | 75–90%  | Caution       |
| Red    | 90–100% | Nearly full   |

The script has zero dependencies, runs in under 100ms, and handles edge cases gracefully (null fields before the first API call, missing data, auto-compaction resets).

## Ownership detection

The installer embeds a `# claude-context-window` marker comment in the settings.json command string. This allows safe uninstall — the tool only removes its own statusLine entry and will not touch configurations from other tools.

## Requirements

- Node.js >= 18
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## License

[MIT](LICENSE)
