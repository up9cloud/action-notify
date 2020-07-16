# action-notify

## Env variables

- You can use [Github action variables](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables#default-environment-variables)
- or use this action built in variables
- or make custom variable by import from [GitHub context](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#contexts)
- or make your own variable

### Built in Env

| name               | description |
| ------------------ | ----------- |
| TELEGRAM_BOT_TOKEN |             |
| TELEGRAM_CHAT_ID   |             |

## Examples

> Custom template example

```txt
chat id: ${TELEGRAM_CHAT_ID}
owner: ${REPO_OWNER}
custom var: ${CUSTOM_VAR1}
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
      env:
        TELEGRAM_BOT_TOKEN: ${{secrets.TELEGRAM_BOT_TOKEN}}
        TELEGRAM_CHAT_ID: ${{secrets.TELEGRAM_CHAT_ID}}
        # Custom template file path relative to the repo
        TEMPLATE_PATH: "./test/custom.txt"
        # Set a custom variable from github context
        REPO_OWNER: ${{github.repository_owner}}
        # Set a custom variable
        CUSTOM_VAR1: "a custom variable"
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
