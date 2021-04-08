# action-notify

Send notifications all in one.

- [x] Telegram: [telegram-bot-send.sh](https://github.com/up9cloud/telegram-bot-send.sh)
- Slack
  - [x] via [Incoming WebHooks](https://api.slack.com/messaging/webhooks) app.
  - [x] via [chat.postMessage](https://api.slack.com/methods/chat.postMessage) api.
- Discord
  - [x] via [Webhooks](https://discord.com/developers/docs/resources/webhook#execute-webhook)
  - [ ] via [/channels/{channel.id}/messages](https://discord.com/developers/docs/resources/channel#create-message)
- [ ] Teams
- [ ] Gitter
- [ ] Line
- [ ] IRC
- [ ] Android push notifications
- [ ] iOS APNs
- [ ] Facebook
- [ ] Google Chat

## Usage

```yml
# Beware on `pull_request`! It might leak your secret!
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Notify telegram
        # Remember to choose correct version: https://github.com/marketplace/actions/action-notify
        uses: up9cloud/action-notify@master
        if: cancelled() == false
        env:
          GITHUB_JOB_STATUS: ${{ job.status }}
          TELEGRAM_BOT_TOKEN: ${{secrets.TELEGRAM_BOT_TOKEN}}
          TELEGRAM_CHAT_ID: ${{secrets.TELEGRAM_CHAT_ID}}
```

## Usage (Custom template)

Template will be parsed by [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html).

```txt
Run number: ${GITHUB_RUN_NUMBER}
Commit message: ${GIT_HEAD_COMMIT_MESSAGE}
Repo owner: ${CUSTOM_VAR1}
Custom var: ${CUSTOM_VAR2}
```

> Workflow example

```yml
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Notify telegram
        uses: up9cloud/action-notify@master
        if: cancelled() == false
        env:
          GITHUB_JOB_STATUS: ${{ job.status }}
          TELEGRAM_BOT_TOKEN: ${{secrets.TELEGRAM_BOT_TOKEN}}
          TELEGRAM_CHAT_ID: ${{secrets.TELEGRAM_CHAT_ID}}
          # Custom template file path, relative to the repo root
          TELEGRAM_TEMPLATE_PATH: "./test/telegram/custom.txt"
          CUSTOM_VAR1: ${{github.repository_owner}}
          CUSTOM_VAR2: "a custom variable"
```

## More examples

[here](https://github.com/up9cloud/action-notify/blob/master/.github/workflows/main.yml)

## Env variables

You can:

- Use following built in variables
- Use [Github action variables](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables)
- Make your own custom variables from [GitHub context](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#contexts) or whatever you need

| Name                            | Description                                                                                         |
| ------------------------------- | --------------------------------------------------------------------------------------------------- |
| GITHUB_JOB_STATUS               | Let entrypoint.sh knows job status.                                                                 |
| GITHUB_JOB_STATUS_COLOR         | The RGB color hex code of job status.                                                               |
| GITHUB_JOB_SUCCESS_COLOR        | The success color, default is `#22863a`.                                                            |
| GITHUB_JOB_FAILURE_COLOR        | The failure color, default is `#cb2431`.                                                            |
| GITHUB_JOB_CANCELLED_COLOR      | The cancelled color, default is `#6a737d`.                                                          |
| GITHUB_JOB_STATUS_EMOJI         | The emoji of job status.                                                                            |
| GITHUB_JOB_SUCCESS_EMOJI        | The success emoji, default is `🟢`.                                                                  |
| GITHUB_JOB_FAILURE_EMOJI        | The failure emoji, default is `🔴`.                                                                  |
| GITHUB_JOB_CANCELLED_EMOJI      | The cancelled emoji, default is `⚪️`.                                                               |
| GITHUB_SHA_SHORT                | Shorter GITHUB_SHA (`cut -c1-8`).                                                                   |
| GIT_HEAD_COMMIT_MESSAGE         | Event: `.head_commit.message` (See ./test/event.json from GITHUB_EVENT_PATH).                       |
| GIT_HEAD_COMMIT_MESSAGE_ESCAPED | Same as GIT_HEAD_COMMIT_MESSAGE, but escaped, can be safely used in JSON template.                  |
| GIT_HEAD_COMMITTER_USERNAME     | Event: `.head_commit.committer.username`.                                                           |
| GIT_COMMIT_MESSAGE              | Event: `.commits[0].message`.                                                                       |
| GIT_COMMIT_MESSAGE_ESCAPED      | Same as GIT_COMMIT_MESSAGE, but escaped, can be safely used in JSON template.                       |
| GIT_COMMITTER_USERNAME          | Event: `.commits[0].committer.username`.                                                            |
| TEMPLATE                        | Built in template style, see `./template/<vendor>/${TEMPLATE}.<ext>`.                               |
| CUSTOM_SCRIPT                   | Run custom script, ignore default action.                                                           |
| TELEGRAM_TEMPLATE_PATH          | Telegram template file path.                                                                        |
| TELEGRAM_BOT_TOKEN              | Get it from [@BotFather](https://telegram.me/BotFather).                                            |
| TELEGRAM_CHAT_ID                | (Send messages to bot), then get it from `https://api.telegram.org/bot<token>/getUpdates`.          |
| TELEGRAM_PARSE_MODE             | `txt` (default), `md` or `html`. See [mode](https://core.telegram.org/bots/api#formatting-options). |
| SLACK_TEMPLATE_PATH             | Slack template file path.                                                                           |
| SLACK_WEBHOOK_URL               | Get it from `Incoming WebHooks` app.                                                                |
| SLACK_API_TOKEN                 | Slack api token, various. If you were using bot token, remember `/invite @BOT_NAME` first.          |
| SLACK_CHANNEL                   | Slack channel id (e.q. `#general`).                                                                 |
| DISCORD_TEMPLATE_PATH           | Discord template file path.                                                                         |
| DISCORD_WEBHOOK_URL             | Get it from `Edit Channel -> Integrations -> Webhooks`                                              |
