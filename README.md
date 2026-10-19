# action-notify

Send CI notifications to many platforms from one action.

- [x] Telegram, via [telegram-bot-send.sh](https://github.com/up9cloud/telegram-bot-send.sh)
- Slack
  - [x] via the [Incoming WebHooks](https://api.slack.com/messaging/webhooks) app
  - [x] via the [chat.postMessage](https://api.slack.com/methods/chat.postMessage) API
- Discord
  - [x] via [Webhooks](https://discord.com/developers/docs/resources/webhook#execute-webhook)
  - [x] via a bot, with [/channels/{channel.id}/messages](https://discord.com/developers/docs/resources/channel#create-message)
- [x] Line
- [ ] Teams
- [ ] Gitter
- [ ] IRC
- [ ] Android push notifications
- [ ] iOS APNs
- [ ] Facebook
- [ ] Google Chat

## Usage

### GitHub Actions

```yml
# Pull requests from forks don't get secrets (secrets.xxx), so this won't work for them.
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Notify telegram
        # You could use master version, but it's recommended to use
        # [latest release version](https://github.com/marketplace/actions/action-notify) instead.
        uses: up9cloud/action-notify@master
        if: cancelled() == false
        env:
          GITHUB_JOB_STATUS: ${{ job.status }}
          TELEGRAM_BOT_TOKEN: ${{secrets.TELEGRAM_BOT_TOKEN}}
          TELEGRAM_CHAT_ID: ${{secrets.TELEGRAM_CHAT_ID}}
  # Or notify from a separate job:
  notify:
    if: cancelled() == false
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - uses: up9cloud/action-notify@master
        env:
          GITHUB_JOB_STATUS: ${{ needs.deploy.result }}
          TELEGRAM_BOT_TOKEN: ${{secrets.TELEGRAM_BOT_TOKEN}}
          TELEGRAM_CHAT_ID: ${{secrets.TELEGRAM_CHAT_ID}}
          # Custom template file, relative to the repo root
          TELEGRAM_TEMPLATE_PATH: "./test/telegram/custom.txt"
          # Custom variables for the template, e.g. from the [GitHub context](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#contexts)
          CUSTOM_VAR1: ${{github.repository_owner}}
          CUSTOM_VAR2: "a custom variable"
```

More examples: [`.github/workflows/main.yml`](https://github.com/up9cloud/action-notify/blob/master/.github/workflows/main.yml)

### Drone CI

```yml
kind: pipeline
name: after

steps:
- name: notify
  image: sstc/action-notify
  environment:
    CUSTOM_VAR2: "a custom variable in environment"
  settings:
    telegram_bot_token:
      from_secret: telegram_bot_token
    telegram_chat_id:
      from_secret: telegram_chat_id
    custom_var2: "a custom variable in settings"
```

## Custom templates

Templates are rendered with [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html), so any environment variable can be used, e.g.

```txt
Commit message: ${GIT_COMMIT_MESSAGE}
Repo owner: ${CUSTOM_VAR1}
Custom var: ${CUSTOM_VAR2}
Custom var in drone plugin settings: ${PLUGIN_CUSTOM_VAR2}
```

The built-in templates under `./template/` are more examples.

## Environment variables

A template can use:

- the CI's own variables
  - GitHub Actions: [default environment variables](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables)
  - Drone CI: [environment reference](https://docs.drone.io/pipeline/environment/reference/)
- your own variables, see [Usage](#usage)
- the variables this action sets, listed below

### General

- `GITHUB_JOB_STATUS`: **Required** on GitHub Actions, since an action cannot read the job status by itself.

  ```yml
  env:
    GITHUB_JOB_STATUS: ${{ job.status }}
  ```

- `CUSTOM_SCRIPT`: A script to run **instead of** the built-in notifiers.
  - e.g. with `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` also set, only `CUSTOM_SCRIPT` runs; the built-in Telegram notifier does not.
- `VERBOSE`: Print logs, `true` or `false` (Drone CI: `verbose` in settings)
  - *Default value*: `false`

### Platforms

- Telegram
  - `TELEGRAM_BOT_TOKEN`: **Required** for Telegram. Get it from [@BotFather](https://telegram.me/BotFather)
    - e.g. `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`
  - `TELEGRAM_CHAT_ID`: **Required** for Telegram. Send the bot a message first, then find it in `https://api.telegram.org/bot<token>/getUpdates`
    - e.g. `-123456789`
  - `TELEGRAM_MESSAGE_THREAD_ID`: The topic ID, `message_thread_id` in `/getUpdates`
  - `TELEGRAM_PARSE_MODE`: Passed to [tg.ash](https://github.com/up9cloud/telegram-bot-send.sh) `--parse-mode`: `text`, `md`, `html`, `code`, `MarkdownV2` or `HTML`. `md` and `html` use the rich message API; `MarkdownV2` and `HTML` use the classic [formatting options](https://core.telegram.org/bots/api#formatting-options). `txt` is an alias of `text`.
    - *Default value*: `text`
  - `TELEGRAM_TEMPLATE_PATH`: Template file path
    - *Default value*: `./template/telegram/${TEMPLATE}.<ext>`, where `<ext>` depends on `TELEGRAM_PARSE_MODE`: `md` → `md`, `html` → `html`, `MarkdownV2` → `MarkdownV2.md`, `HTML` → `HTML.html`, anything else → `txt`
  - `TELEGRAM_TEMPLATE_CONTENT`: Template content. Takes precedence over `TELEGRAM_TEMPLATE_PATH`
- Slack
  - `SLACK_WEBHOOK_URL`: **Required** to send via webhook. Get it from the Incoming WebHooks app
    - e.g. `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX`
  - `SLACK_API_TOKEN`: **Required** to send via API. When using a bot token, `/invite @BOT_NAME` into the channel first
  - `SLACK_CHANNEL`: Channel ID or name. **Required** to send via API, optional via webhook
    - e.g. `#general`
  - `SLACK_TEMPLATE_PATH`: Template file path
    - *Default value*: `./template/slack/${TEMPLATE}.json`
  - `SLACK_TEMPLATE_CONTENT`: Template content. Takes precedence over `SLACK_TEMPLATE_PATH`
- Discord
  - `DISCORD_WEBHOOK_URL`: **Required** to send via webhook. Get it from `Edit Channel -> Integrations -> Webhooks`
  - `DISCORD_BOT_TOKEN`: **Required** to send via bot.
    1. Get the token from [Developer Applications](https://discord.com/developers/applications): `New Application (or choose an existing one) -> Bot -> Token`
    2. Add the bot to your server: `https://discord.com/api/oauth2/authorize?client_id=<client_id>&permissions=0&scope=bot%20applications.commands`. The `client_id` is under [Developer Applications](https://discord.com/developers/applications) -> the application -> `OAuth2 -> CLIENT ID`
    3. For a private channel, also add the bot to it: `Edit Channel -> Permissions -> Add members or roles`
  - `DISCORD_CHANNEL_ID`: **Required** to send via bot. Enable `User Settings -> Advanced -> Developer Mode`, then right-click the channel -> `Copy ID`. It is also the last part of the channel's URL in the browser, e.g. `https://discord.com/channels/.../<channel id>`
  - `DISCORD_TEMPLATE_PATH`: Template file path
    - *Default value*: `./template/discord/${TEMPLATE}.json`
  - `DISCORD_TEMPLATE_CONTENT`: Template content. Takes precedence over `DISCORD_TEMPLATE_PATH`
- Line
  - `LINE_CHANNEL_ACCESS_TOKEN`: **Required** for Line. Get it from the developer console: `Bot -> Messaging API -> Channel access token (long-lived)`
  - `LINE_TO`: **Required** for Line. The user, group or chat ID of the recipient, found in webhook payloads (which needs your own webhook server)
    - Multiple IDs are separated by commas, and must all be user IDs. To notify a mix of user, group and chat IDs, run this action once per ID.

      ```yml
      env:
        LINE_TO: "Uxxxxxxxxxxx,Uxxxxxxxxxxx"
      ```

  - `LINE_TEMPLATE_PATH`: Template file path
    - *Default value*: `./template/line.me/${TEMPLATE}.json`
  - `LINE_TEMPLATE_CONTENT`: Template content. Takes precedence over `LINE_TEMPLATE_PATH`

### Template variables

- `TEMPLATE`: Built-in template style, `./template/<platform>/${TEMPLATE}.<ext>`: `debug`, `default` or `default.drone`
  - *Default value*: `default` on GitHub Actions, `default.drone` on Drone CI
- `GIT_SHA_SHORT`: The first 8 characters of the commit SHA
- `GIT_COMMIT_MESSAGE`
  - GitHub Actions: the first of the event's `.commits[-1].message`, `.head_commit.message`, `.workflow_run.head_commit.message` or `.pull_request.title`; `(<event name> event)` when there is none, e.g. on `schedule`
  - Drone CI: `DRONE_COMMIT_MESSAGE`
- `GIT_COMMIT_MESSAGE_ESCAPED`: `GIT_COMMIT_MESSAGE` escaped for JSON
  - e.g. `{"msg":"${GIT_COMMIT_MESSAGE_ESCAPED}"}`
- `GIT_COMMIT_MESSAGE_HTML_ESCAPED`: `GIT_COMMIT_MESSAGE` with `&`, `<` and `>` escaped, for HTML
  - e.g. `<pre>${GIT_COMMIT_MESSAGE_HTML_ESCAPED}</pre>`
- `GIT_COMMITTER_USERNAME`
  - GitHub Actions: the first of the event's `.commits[-1].committer.username`, `.head_commit.committer.username` or `.workflow_run.head_commit.committer.name`; `GITHUB_ACTOR` when there is none
  - Drone CI: `DRONE_COMMIT_AUTHOR`
- `STATUS_COLOR`: Hex RGB color for the job status, set by:
  - `STATUS_COLOR_SUCCESS`: *Default value*: `#22863a`
  - `STATUS_COLOR_FAILURE`: *Default value*: `#cb2431`
  - `STATUS_COLOR_CANCELLED`: *Default value*: `#6a737d`
- `STATUS_COLOR_DECIMAL`: `STATUS_COLOR` as a decimal number
- `STATUS_EMOJI`: Emoji for the job status, set by:
  - `STATUS_EMOJI_SUCCESS`: *Default value*: `🟢`
  - `STATUS_EMOJI_FAILURE`: *Default value*: `🔴`
  - `STATUS_EMOJI_CANCELLED`: *Default value*: `⚪️`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md), including how to release.
