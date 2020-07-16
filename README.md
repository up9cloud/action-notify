# action-notify

## Env variables

| name                       | description                                                |
| -------------------------- | ---------------------------------------------------------- |
| GITHUB_JOB_STATUS          | Let action knows job status.                               |
| TEMPLATE                   | Choose built in template, see `./template/${TEMPLATE}.txt` |
| TEMPLATE_PATH              | Set custom template file path                              |
| GIT_HEAD_COMMIT_MESSAGE    | Event: `.head_commit.message` (See ./test/event.json)      |
| GIT_HEAD_COMMITER_USERNAME | Event: `.head_commit.commiter.username`.                   |
| GIT_COMMIT_MESSAGE         | Event: `.commits[0].message`                               |
| GIT_COMMITER_USERNAME      | Event: `.commits[0].commiter.username`                     |
| CUSTOM_SCRIPT              | Set custom script, do not run default behavior.            |
| TELEGRAM_BOT_TOKEN         |                                                            |
| TELEGRAM_CHAT_ID           |                                                            |

- You can use above built in variables.
- or use [Github action variables](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables)
- or make custom variables from [GitHub context](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#contexts)
- or make your own variables

## Examples

> Custom template example

Template will format by [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html) program.

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
          TEMPLATE_PATH: "./test/custom.txt"
          # Set a custom variable from github context
          CUSTOM_VAR1: ${{github.repository_owner}}
          # Set a custom variable
          CUSTOM_VAR2: "a custom variable"
```

See [more examples](https://github.com/up9cloud/action-notify/blob/master/.github/workflows/main.yml)

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
