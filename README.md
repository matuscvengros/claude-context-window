# Claude: Context Bar

[![CI](https://github.com/matuscvengros/claude-context-bar/actions/workflows/ci.yml/badge.svg)](https://github.com/matuscvengros/claude-context-bar/actions/workflows/ci.yml)
[![npm version](https://img.shields.io/npm/v/claude-context-bar)](https://www.npmjs.com/package/claude-context-bar)
[![Downloads](https://img.shields.io/npm/dm/claude-context-bar)](https://www.npmjs.com/package/claude-context-bar)
[![License](https://img.shields.io/npm/l/claude-context-bar)](https://github.com/matuscvengros/claude-context-bar/blob/main/LICENSE)

Real-time context window usage bar for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Shows a colored progress bar in the Claude Code status line that fills up as your context window is consumed.

```
Opus 4.6 │ █░░░░░░░░░ 10% │ 100K/1M tokens     ← green
Opus 4.6 │ █████░░░░░ 50% │ 500K/1M tokens     ← yellow
Opus 4.6 │ ████████░░ 78% │ 780K/1M tokens     ← orange
Opus 4.6 │ █████████░ 90% │ 900K/1M tokens     ← red
```

## Install

```sh
npx claude-context-bar@latest install
```

Restart Claude Code to activate.

## Uninstall

```sh
npx claude-context-bar@latest uninstall
```

## How it works

The installer copies a lightweight Node.js script to `~/.claude/claude-context-bar.js` and configures the `statusLine` setting in `~/.claude/settings.json`. Claude Code periodically invokes the script, passing context window metrics via stdin. The script outputs a formatted, color-coded status line.

**Colors indicate context usage:**

| Color  | Usage     | Meaning         |
|--------|-----------|-----------------|
| Green  | 0–50%     | Plenty of room  |
| Yellow | 50–75%    | Getting there   |
| Orange | 75–90%    | Caution         |
| Red    | 90–100%   | Nearly full     |

## Requirements

- Node.js >= 18
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## License

[MIT](LICENSE)
