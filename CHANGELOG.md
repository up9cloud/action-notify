# Changelog

## v0.6 (2026-10-19)

### Breaking

- **Failed sends now fail the step.** Slack (webhook and `chat.postMessage`), Discord webhook and
  Telegram failures used to pass silently. Every notifier now checks the response, and the step
  fails once all notifiers have run. Slack API errors such as `invalid_auth` or
  `legacy_custom_bots_deprecated` now show up instead of being ignored.
- **One failing notifier no longer stops the rest.** A Telegram error used to abort the script
  before Slack, Discord or Line were tried.
- **Telegram `md` and `html` parse modes now use the rich message API** of
  [tg.ash](https://github.com/up9cloud/telegram-bot-send.sh) v2, with new default templates. To
  keep the previous rendering, use `TELEGRAM_PARSE_MODE: MarkdownV2` or `HTML`, whose templates
  are the old `md` and `html` ones. `markdown` and `Markdown` are no longer mapped to a Markdown
  template; `txt` still works as an alias of `text`.

### Added

- `GIT_COMMIT_MESSAGE_HTML_ESCAPED`, for HTML templates.
- `TELEGRAM_PARSE_MODE: code`.
- For events without commits, `GIT_COMMIT_MESSAGE` falls back to the head commit (tag pushes),
  then the PR title (`pull_request`), then `(<event name> event)` (`schedule`,
  `workflow_dispatch`, ...); `GIT_COMMITTER_USERNAME` falls back to `GITHUB_ACTOR`.

### Fixed

- Commit messages containing `%` or `\` are no longer mangled.
- Events without commits no longer show the literal string `null`.
- Invalid `STATUS_COLOR_*` values fall back to `#ffffff` with a warning instead of crashing.
- Running outside GitHub Actions and Drone works again.
- Drone: default templates, `*_TEMPLATE_CONTENT`, `template` and `verbose` settings are honored.
- Telegram: setting `TELEGRAM_PARSE_MODE` no longer drops `TELEGRAM_MESSAGE_THREAD_ID`.
- Telegram `MarkdownV2` default templates no longer break on refs containing `.`, `-` or `_`,
  e.g. `refs/tags/v1.0`.
- Telegram HTML parse mode no longer breaks on `<...>` in commit messages, e.g. a
  `Co-Authored-By` email.
- The `debug` template no longer breaks on multi-line commit messages, and fits Telegram's and
  Slack's message size limits.
- Discord bot API moved to `discord.com/api/v10`.
