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
Commit message: ${GIT_COMMIT_MESSAGE}
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

[Here](https://github.com/up9cloud/action-notify/blob/master/.github/workflows/main.yml)

## Env variables

You can:

- Use Github built-in [default environment variables](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables)
- Assign [GitHub context](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#contexts) to env variable and use it, e.q. `CUSTOM_VAR1: ${{github.repository_owner}}`
- Make custom env variable, e.q. `CUSTOM_VAR2: "a custom var"`
- Use following built in variables:

> Common

- `GITHUB_JOB_STATUS`: You have to set this to let entrypoint.sh knows job status.
  - **Required**
  - e.q. `GITHUB_JOB_STATUS: ${{ job.status }}`
- `GITHUB_JOB_STATUS_COLOR`: The RGB color hex code of job status
- `GITHUB_JOB_SUCCESS_COLOR`: The success color
  - *Default value*: `#22863a`
- `GITHUB_JOB_FAILURE_COLOR`: The failure color
  - *Default value*: `#cb2431`
- `GITHUB_JOB_CANCELLED_COLOR`: The cancelled color
  - *Default value*: `#6a737d`
- `GITHUB_JOB_STATUS_EMOJI`: The emoji of job status.
- `GITHUB_JOB_SUCCESS_EMOJI`: The success emoji
  - *Default value*: `🟢`
- `GITHUB_JOB_FAILURE_EMOJI`: The failure emoji
  - *Default value*: `🔴`
- `GITHUB_JOB_CANCELLED_EMOJI`: The cancelled emoji
  - *Default value*: `⚪️`
- `GITHUB_SHA_SHORT`: Shorter GITHUB_SHA `cut -c1-8`
- `GIT_HEAD_COMMIT_MESSAGE`: Event value `.head_commit.message` (See ./test/event.json from GITHUB_EVENT_PATH)
- `GIT_HEAD_COMMIT_MESSAGE_ESCAPED`: Same as GIT_HEAD_COMMIT_MESSAGE, but escaped, can be safely used in JSON template
- `GIT_HEAD_COMMITTER_USERNAME`: Event value `.head_commit.committer.username`
- `GIT_COMMIT_MESSAGE`: Event value `.commits[-1].message`
- `GIT_COMMIT_MESSAGE_ESCAPED`: Same as GIT_COMMIT_MESSAGE, but escaped, can be safely used in JSON template
- `GIT_COMMITTER_USERNAME`: Event value `.commits[-1].committer.username`
- `TEMPLATE`: Built in template style, for now only 2 kinds -- `debug` and `default`, see `./template/<vendor variants>/${TEMPLATE}.<ext>`
  - *Default value*: default
- `CUSTOM_SCRIPT`: Run custom script, and will **ignore** default action
  - e.q. if you set this with TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID, it will **only** run your CUSTOM_SCRIPT instead running built-in notify_telegram function
- `VERBOSE`: show log or not, true or false
  - *Default value*: false

> Platform variables

- `TELEGRAM_TEMPLATE_PATH`: Telegram template file path
  - *Default value*: `./template/telegram/${TEMPLATE}.${TELEGRAM_PARSE_MODE}`
- `TELEGRAM_BOT_TOKEN`: Get it from [@BotFather](https://telegram.me/BotFather)
  - **Required if** want to notify telegram
  - e.q. 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
- `TELEGRAM_CHAT_ID`: First sending messages to bot, then get it from `https://api.telegram.org/bot<token>/getUpdates`
  - **Required if** want to notify telegram
  - e.q. -123456789
- `TELEGRAM_PARSE_MODE`: `txt`, `md` or `html`. This will map to telegram [formatting options](https://core.telegram.org/bots/api#formatting-options)
  - *Default value*: `txt`
- `SLACK_TEMPLATE_PATH`: Slack template file path
  - *Default value*: `./template/slack/${TEMPLATE}.json`
- `SLACK_WEBHOOK_URL`: Get it from `Incoming WebHooks` app
  - **Required if** want to notify slack via webhook
  - e.q. `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX`
- `SLACK_API_TOKEN`: Slack api token, various. If you were using bot token, remember `/invite @BOT_NAME` first
  - **Required if** want to notify slack via api
- `SLACK_CHANNEL`: Slack channel id
  - **Required if** want to notify slack via api. this also can be used by webhook, but not required
  - e.q. `#general`
- `DISCORD_TEMPLATE_PATH`: Discord template file path
  - *Default value*: `./template/discord/${TEMPLATE}.json`
- `DISCORD_WEBHOOK_URL`: Get it from `Edit Channel -> Integrations -> Webhooks`
  - **Required if** want to notify discord via webhook
