# action-notify

Send notifications all in one.

- [x] Telegram: by [telegram-bot-send.sh](https://github.com/up9cloud/telegram-bot-send.sh)
- Slack
  - [x] via [Incoming WebHooks](https://api.slack.com/messaging/webhooks) app.
  - [x] via [chat.postMessage](https://api.slack.com/methods/chat.postMessage) api.
- Discord
  - [x] via [Webhooks](https://discord.com/developers/docs/resources/webhook#execute-webhook)
  - [ ] via [/channels/{channel.id}/messages](https://discord.com/developers/docs/resources/channel#create-message)
- [ ] Teams
- [ ] Gitter
- [x] Line
- [ ] IRC
- [ ] Android push notifications
- [ ] iOS APNs
- [ ] Facebook
- [ ] Google Chat

## Usage

> GitHub Action

```yml
# It won't work on `pull_request`, github won't pass secrets.xxx for the workflow triggered by pull request
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Notify telegram
        # You could use master version, but it's recommended to use [latest release version](https://github.com/marketplace/actions/action-notify) instead.
        uses: up9cloud/action-notify@master
        if: cancelled() == false
        env:
          GITHUB_JOB_STATUS: ${{ job.status }}
          TELEGRAM_BOT_TOKEN: ${{secrets.TELEGRAM_BOT_TOKEN}}
          TELEGRAM_CHAT_ID: ${{secrets.TELEGRAM_CHAT_ID}}
  # Or you could use this as standalone job:
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
          # Custom template file path, relative to the repo root
          TELEGRAM_TEMPLATE_PATH: "./test/telegram/custom.txt"
          # Custom env, assign it from [GitHub context](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#contexts)
          CUSTOM_VAR1: ${{github.repository_owner}}
          CUSTOM_VAR2: "a custom variable"
```

See more usage examples: [`.github/workflows/main.yml`](https://github.com/up9cloud/action-notify/blob/master/.github/workflows/main.yml)

> Drone CI

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

## Custom template

Template will be parsed by [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html), e.q.

```txt
Commit message: ${GIT_COMMIT_MESSAGE}
Repo owner: ${CUSTOM_VAR1}
Custom var: ${CUSTOM_VAR2}
Custom var in drone plugin settings: ${PLUGIN_CUSTOM_VAR2}
```

See more template examples: `./template/**/*`

## Env variables

You can:

- Use CI built-in env
  - GitHub Action: [default environment variables](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables)
  - Drone CI: pipeline [environment reference](https://docs.drone.io/pipeline/environment/reference/) if you're running Drone CI
- Customize by yourself, see usage
- Use following built-in env

### Built-in variables

Common ones:

- `GITHUB_JOB_STATUS`: **Required if** you're using `GitHub Action`, have to set this to let entrypoint.sh knows job status.

  ```yml
  env:
    GITHUB_JOB_STATUS: ${{ job.status }}
  ```

- `CUSTOM_SCRIPT`: Run custom script, and will **ignore** default action
  - e.q. if you set this with TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID, it will **only** run your CUSTOM_SCRIPT instead trigger built-in notify_telegram function
- `VERBOSE`: show log or not, true or false
  - *Default value*: false

Platform related:

- `Telegram`
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
- `Slack`
  - `SLACK_TEMPLATE_PATH`: Slack template file path
    - *Default value*: `./template/slack/${TEMPLATE}.json`
  - `SLACK_WEBHOOK_URL`: Get it from `Incoming WebHooks` app
    - **Required if** want to notify slack via webhook
    - e.q. `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX`
  - `SLACK_API_TOKEN`: Slack api token, various. If you were using bot token, remember `/invite @BOT_NAME` first
    - **Required if** want to notify slack via api
  - `SLACK_CHANNEL`: Slack channel id
    - **Required if** want to notify slack via api. (good to have if via webhook)
    - e.q. `#general`
- `Discord`
  - `DISCORD_TEMPLATE_PATH`: Discord template file path
    - *Default value*: `./template/discord/${TEMPLATE}.json`
  - `DISCORD_WEBHOOK_URL`: Get it from `Edit Channel -> Integrations -> Webhooks`
    - **Required if** want to notify discord via webhook
- `Line`
  - `LINE_TEMPLATE_PATH`: Line.me template file path
    - *Default value*: `./template/line.me/${TEMPLATE}.json`
  - `LINE_CHANNEL_ACCESS_TOKEN`: Get it from Developer console -> Bot -> `Messaging api -> Channel access token (long-lived)`
    - **Required if** want to notify line.me
  - `LINE_TO`: The user id, group id or chat id. Get it from webhook objects (have to build your server to receive objects)
    - **Required if** want to notify line.me
    - It can be multiple ids
      - Must be `user`s, if you want to notify mixed ids with group or chat id, you `have` to trigger this action one by one.
      - Using `,` to separate each id, e.q.

      ```yml
      env:
        LINE_TO: "Uxxxxxxxxxxx,Uxxxxxxxxxxx"
      ```

Template related

- `TEMPLATE`: Built in template style, see `./template/<vendor variants>/${TEMPLATE}.<ext>`
  - Could be `debug`, `default` or `default.drone`
  - *Default value*
    - GitHub Action: default
    - Drone CI: default.drone
- `GIT_SHA_SHORT`: Shorter commit sha `cut -c1-8`
- `GIT_COMMIT_MESSAGE`
  - GitHub Action: event's value `.commits[-1].message`, `.workflow_run.head_commit.message`
  - Drone CI: same as DRONE_COMMIT_MESSAGE
- `GIT_COMMIT_MESSAGE_ESCAPED`: Same as GIT_COMMIT_MESSAGE, but escaped, can be safely used in JSON template
  - e.q. `{"msg":"${GIT_COMMIT_MESSAGE_ESCAPED}"}`
- `GIT_COMMITTER_USERNAME`
  - GitHub Action: event's value `.commits[-1].committer.username`, `.workflow_run.head_commit.committer.name`
  - Drone CI: same as DRONE_COMMIT_AUTHOR

- `STATUS_COLOR`: The RGB color hex code based on job status and following settings:
  - `STATUS_COLOR_SUCCESS`: The success color
    - *Default value*: `#22863a`
  - `STATUS_COLOR_FAILURE`: The failure color
    - *Default value*: `#cb2431`
  - `STATUS_COLOR_CANCELLED`: The cancelled color
    - *Default value*: `#6a737d`
- `STATUS_COLOR_DECIMAL`: The decimal code of `STATUS_COLOR`
- `STATUS_EMOJI`: The emoji based on job status and following settings:
  - `STATUS_EMOJI_SUCCESS`: The success emoji
    - *Default value*: `🟢`
  - `STATUS_EMOJI_FAILURE`: The failure emoji
    - *Default value*: `🔴`
  - `STATUS_EMOJI_CANCELLED`: The cancelled emoji
    - *Default value*: `⚪️`
