# action-notify

## Env variables

| name                        | In template | description                                                       |
| --------------------------- | ----------- | ----------------------------------------------------------------- |
| GITHUB_JOB_STATUS           |             | Let action knows job status.                                      |
| GIT_HEAD_COMMIT_MESSAGE     |             | Event: `.head_commit.message` (See ./test/event.json)             |
| GIT_HEAD_COMMITTER_USERNAME |             | Event: `.head_commit.committer.username`.                         |
| GIT_COMMIT_MESSAGE          |             | Event: `.commits[0].message`                                      |
| GIT_COMMITTER_USERNAME      |             | Event: `.commits[0].committer.username`                           |
| TEMPLATE                    | No          | Choose built in template, see `./template/<type>/${TEMPLATE}.txt` |
| CUSTOM_SCRIPT               | No          | Set custom script, not run default behavior.                      |
| TELEGRAM_BOT_TOKEN          | No          |                                                                   |
| TELEGRAM_CHAT_ID            | No          |                                                                   |
| TELEGRAM_PARSE_MODE         | No          | See [mode](https://core.telegram.org/bots/api#formatting-options) |
| TELEGRAM_TEMPLATE_PATH      | No          | Set custom telegram template file path                            |

> If you wanted to use variables not allow in template, you should write custom script and `export` the variables, or you could make custom ones in `step`.

- You can use above built in variables.
- or use [Github action variables](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables)
- or make custom variables from [GitHub context](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#contexts)
- or make your own variables

## Examples

> Custom template example

Template will be parsed by [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html) program.

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
        uses: up9cloud/action-notify@v1
        if: cancelled() == false
        env:
          GITHUB_JOB_STATUS: ${{ job.status }}
          TELEGRAM_BOT_TOKEN: ${{secrets.TELEGRAM_BOT_TOKEN}}
          TELEGRAM_CHAT_ID: ${{secrets.TELEGRAM_CHAT_ID}}
          # Custom template file path relative to the repo root
          TELEGRAM_TEMPLATE_PATH: "./test/custom.txt"
          # Set a custom variable from github context
          CUSTOM_VAR1: ${{github.repository_owner}}
          # Set a custom variable
          CUSTOM_VAR2: "a custom variable"
```

See more [examples](https://github.com/up9cloud/action-notify/blob/master/.github/workflows/main.yml)

## TODO

- [x] Telegram
- [ ] Webhook
- [ ] Slack
- [ ] Discord
- [ ] Teams
- [ ] Gitter
- [ ] Line
- [ ] IRC
- [ ] Android push notifications
- [ ] IOS APNs
- [ ] Facebook
- [ ] Google Chat
